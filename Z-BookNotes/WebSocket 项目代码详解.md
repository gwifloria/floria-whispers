-
  WebSocket 项目代码详解

  一、文件结构与依赖关系

  src/
  ├── createSocket/                    # 核心 WebSocket 层
  │   ├── types.ts                     # 类型定义 (WSState, URLBuilder, OnClose 等)
  │   ├── WebSocketHub.ts              # 多连接管理器
  │   └── WSWrapper/
  │       ├── types.ts                 # WSWrapper 相关类型
  │       ├── instance.ts              # 创建原生 WebSocket 实例
  │       ├── WSWrapper.ts             # 单连接状态机
  │       ├── SendBuffer.ts            # 消息缓冲区
  │       └── index.ts                 # WSWrapperProxy (节流+缓冲+防重复)
  │
  ├── react/                           # React Hook 层
  │   ├── useUnmounted.ts
  │   ├── useHarmonicIntervalFn.ts
  │   ├── usePseudoPingpong.ts         # 心跳检测
  │   ├── useWebSocket.ts              # 低级 Hook
  │   └── useApiWebSocket/index.ts     # 高级 Hook
  │
  ├── vue/                             # Vue Composable 层
  │   ├── useMounted.ts
  │   ├── useHarmonicIntervalFn.ts
  │   ├── usePseudoPingpong.ts
  │   ├── useWebSocket.ts
  │   └── useApiWebSocket/
  │       ├── useInterval.ts
  │       ├── useSendData.ts
  │       └── index.ts
  │
  ├── types/index.ts                   # 公共类型定义
  ├── fetch.ts                         # API 获取工具
  └── constant.ts                      # 常量

  依赖关系图：
  useApiWebSocket
         ↓ 使用
  useWebSocket
         ↓ 创建
  WebSocketHub
         ↓ 管理多个
  WSWrapperProxy (index.ts)
         ↓ 包装
  WSWrapper
         ↓ 持有
  原生 WebSocket (通过 instance.ts 创建)

  ---
  二、底层核心：WSWrapper 状态机

  文件：src/createSocket/WSWrapper/WSWrapper.ts

  这是最底层的 WebSocket 包装器，管理单个连接的状态。

  // 第 9-20 行：类定义和构造函数
  class WSWrapper extends EventEmitter {
    private readonly _ws: WebSocketExt;        // 持有的原生 WebSocket
    private _state: WSState = WSState.None;    // 当前状态

    constructor(ws: WebSocketExt) {
      super();                                  // 继承 EventEmitter，可以 emit/on 事件
      this._ws = ws;
      this._state = WSState.Inited;             // 创建时立即进入 Inited 状态
      this.init();
    }

  状态枚举 (src/createSocket/types.ts 第 11-19 行)：
  export enum WSState {
    None,       // 0: 未初始化/错误状态
    Inited,     // 1: 已创建，等待 onopen
    Opened,     // 2: 连接已打开
    Sent,       // 3: 已发送消息
    Received,   // 4: 已接收消息
    Closing,    // 5: 关闭中
    Closed,     // 6: 已关闭
  }

  事件绑定 (第 56-69 行)：
  private webSocketEvents() {
    const ws = this._ws;

    // 把原生 WebSocket 的 4 个事件绑定到本类的方法
    ws.onopen = this.onOpen.bind(this);
    ws.onmessage = this.onMessage.bind(this);
    ws.onclose = this.onClose.bind(this);
    ws.onerror = this.onError.bind(this);

    return this.offWebSocketEvents.bind(this);  // 返回解绑函数
  }

  onOpen 处理 (第 80-86 行)：
  private onOpen(ev: Event) {
    this._state = WSState.Opened;               // 状态变为 Opened
    this.emit("open", ev);                      // 发出 "open" 事件给外部监听者
  }

  onMessage 处理 (第 88-115 行)：
  private onMessage(ev: MessageEvent) {
    this._state = WSState.Received;             // 状态变为 Received

    const { data } = ev;

    let d = null;
    try {
      d = JSON.parse(data);                     // 尝试 JSON 解析
    } catch (err) {
      d = null;                                 // 解析失败返回 null
    }

    this.emit("message", d, ev);                // 发出解析后的数据
  }

  状态判断属性 (第 168-188 行)：
  // 是否可以发送消息
  get sendable() {
    // 只有 Opened/Sent/Received 三种状态可以发送
    return [WSState.Opened, WSState.Sent, WSState.Received].includes(this._state);
  }

  // 连接是否存活
  get alive() {
    if (this.sendable) return true;
    return [WSState.Inited].includes(this._state);  // Inited 也算存活（正在连接中）
  }

  // 是否可以关闭
  get closable() {
    return this.alive;                              // 存活的才能关闭
  }

  ---
  三、消息缓冲：SendBuffer

  文件：src/createSocket/WSWrapper/SendBuffer.ts

  当连接还没建立好时，消息先存在这里。

  export default class SendBuffer<T = string> {
    private readonly maxBufferedCount = 20;     // 最多存 20 条
    private bufferedData: T[];                  // 消息队列
    private isFlushing = false;                 // 防止重入

  存储消息 (第 26-35 行)：
  store(data: T) {
    const len = this.bufferedData.length;

    // 如果已达上限，删除最老的消息腾出空间
    if (len >= this.maxBufferedCount) {
      this.bufferedData.splice(0, len - this.maxBufferedCount + 1);
    }

    this.bufferedData.push(data);               // 添加新消息到末尾
    return true;
  }

  冲刷消息 (第 43-74 行)：
  flush(fn: (data: T) => void) {
    if (this.isFlushing) return;                // 防止重入

    let lastData = this.last;                   // 只取最后一条
    if (lastData === undefined) return;

    this.isFlushing = true;

    try {
      // Option/A: 只发送最后一条（当前采用的策略）
      fn(lastData);

      // Option/B: 发送整个队列（注释掉的备选方案）
      // const bufferedData = this.getCloneAndResetBuffer()
      // for (const buffer of bufferedData) {
      //   fn(buffer);
      // }
    } catch (err) {
      lastData = undefined;
    } finally {
      this.isFlushing = false;
    }

    return lastData;
  }

  为什么只发最后一条？ 因为这个库用于实时设备状态，前面的请求已经过时了，只需要最新的订阅请求。

  ---
  四、增强包装：WSWrapperProxy

  文件：src/createSocket/WSWrapper/index.ts

  在 WSWrapper 基础上添加节流、防重复、缓冲功能。

  节流函数 (第 13-40 行)：
  const throttleSendMsg = function (
    fn: (msg: string, force?: boolean) => any,
    ms = 300                                    // 默认 300ms
  ) {
    let timeout = 0;

    function dispose() {
      if (timeout) {
        window.clearTimeout(timeout);
        timeout = 0;
      }
    }

    const wrapped: ThrottledSendMsg = function (
      this: WSWrapperProxy,
      msg: string,
      force?: boolean
    ) {
      dispose();                                // 清除上一个定时器
      // 延迟 ms 毫秒后执行
      timeout = window.setTimeout(() => fn.call(this, msg, force), ms);
    };

    wrapped.dispose = dispose;
    return wrapped;
  };

  类定义 (第 52-74 行)：
  class WSWrapperProxy {
    private _onmessage?: OnMessage;
    private _onopen?: OnOpen;
    private _onclose?: OriginOnClose;

    private _url: string;
    private _lastMsg = "";                      // 记录上次发送的消息

    private readonly _ws: WebSocketExt;         // 原生 WebSocket
    private readonly _wsWrapper: WSWrapper;     // WSWrapper 实例
    private readonly _sendBuffer: SendBuffer;   // 缓冲区

    private readonly sendMsg: ThrottledSendMsg; // 节流后的发送函数

    constructor(url: string, optional?: WSWrapperOptional) {
      this._url = url;
      this._ws = this.getWebSocketInstance(url, optional);
      this._wsWrapper = new WSWrapper(this._ws);
      this._sendBuffer = new SendBuffer();
      this._lastMsg = "";

      // 用节流函数包装 sendMsg_
      this.sendMsg = throttleSendMsg(this.sendMsg_);
    }

  setOnOpen：连接成功时自动冲刷缓冲区 (第 80-104 行)：
  setOnOpen(onopen?: OnOpen) {
    // ... 省略解绑旧监听器的代码 ...

    if (onopen) {
      const self = this;
      const originOnOpen = onopen;

      // 包装原始的 onopen，在调用后自动冲刷缓冲区
      onopen = function (...args) {
        originOnOpen.call(self, ...args);       // 先调用原始回调
        self.flushSendBuffer();                 // 再冲刷缓冲区
      };
    }

    this._onopen = onopen;
    if (this._onopen) {
      this._wsWrapper.on("open", this._onopen);
    }
  }

  核心发送逻辑 sendMsg_ (第 176-203 行)：
  private sendMsg_(msg: string, force = false) {
    // 1. 检查连接是否存活
    if (!this._wsWrapper.alive) {
      return false;
    }

    // 2. 防重复：如果消息和上次一样且 force=false，拒绝发送
    if (this._lastMsg === msg && !force) {
      WSWrapperProxyLogger.debug(
        "WSWrapperProxy cannot send the same message again"
      );
      return false;
    }

    // 3. 如果连接还没就绪（还在 Inited 状态），存入缓冲区
    if (!this._wsWrapper.sendable) {
      WSWrapperProxyLogger.debug(
        "WSWrapperProxy cannot send immediatly and store in buffer"
      );
      this._sendBuffer.store(msg);
      return true;
    }

    // 4. 连接就绪，先冲刷缓冲区中的消息
    this.flushSendBuffer();

    // 5. 发送当前消息
    this._wsWrapper.send(msg);

    // 6. 记录这次发送的消息
    this.updateLastMessage(msg);

    return true;
  }

  // 公开方法，使用节流版本
  send(msg: string, force = false) {
    return this.sendMsg(msg, force);            // 这是节流后的版本
  }

  冲刷缓冲区 (第 156-174 行)：
  private flushSendBuffer() {
    if (this._sendBuffer.size === 0) return;    // 没有缓冲数据
    if (!this._wsWrapper.sendable) return;      // 连接不可发送

    try {
      // 调用 SendBuffer.flush，传入发送函数
      const lastMsg = this._sendBuffer.flush((data) =>
        this._wsWrapper.send(data)
      );
      this.updateLastMessage(lastMsg);          // 更新最后发送的消息
    } finally {
      /* */
    }
  }

  ---
  五、多连接管理：WebSocketHub

  文件：src/createSocket/WebSocketHub.ts

  管理多个 WSWrapperProxy 实例。

  类定义 (第 17-35 行)：
  export const reconnectTimeout = 1200;         // 重连超时：1.2秒

  export class WebSocketHub {
    private _builder: URLBuilder;               // URL 来源
    private readonly _websockets: Record<string, WSWrapper>;  // url -> WSWrapper 映射

    private _onmessage?: OnMessage;
    private _onopen?: OnOpen;
    private _onclose?: OnClose;
    private _autoConnect = false;               // 是否启用自动重连
    private _autoConnectTimeouts: Record<string, number>;  // 重连定时器
    private _explicitlyClosed = false;          // 是否手动关闭

    private readonly _optional: WebSocketHubOptional | undefined;

    constructor(builder: URLBuilder, optional?: WebSocketHubOptional) {
      this._builder = builder;
      this._websockets = {};
      this._optional = optional;
      this._autoConnectTimeouts = {};
    }

  URLBuilder 类型 (src/createSocket/types.ts 第 21-24 行)：
  export type URLBuilder =
    | string                                    // 单个 URL
    | string[]                                  // URL 数组
    | { build: () => string[]; interval: number };  // 动态构建器

  获取 URL 列表 (第 187-197 行)：
  private getUrls(): string[] {
    if (typeof this._builder === "string") {
      return [this._builder];                   // 单个 URL 包装成数组
    } else if (Array.isArray(this._builder)) {
      return this._builder;                     // 直接返回数组
    } else if ("build" in this._builder && "interval" in this._builder) {
      return this._builder.build();             // 调用构建函数
    }
    return [];
  }

  tryConnect：尝试建立连接 (第 88-113 行)：
  tryConnect() {
    this._explicitlyClosed = false;             // 标记非手动关闭
    this.clearReconnectTimeout();               // 清除所有重连定时器
    this._autoConnect = true;                   // 启用自动重连

    const urls = this.getUrls();                // 获取当前 URL 列表
    const curUrls = Object.keys(this._websockets);  // 当前已有的连接
    const diffUrls = curUrls.filter((x) => !urls.includes(x));  // 需要关闭的

    // 关闭不再需要的连接
    for (const url of diffUrls) {
      this.closeWs(url);
    }

    // 为每个 URL 分配连接
    urls.forEach((url: string) => this.assignWS(url));
  }

  assignWS：分配单个连接 (第 199-231 行)：
  private assignWS(url: string): void {
    let ws = this._websockets[url];
    const state = ws?.getState() ?? null;

    // 如果连接已存在且还能接收消息，不重复创建
    if (ws?.canReceive) {
      return;
    }

    if (state === WSState.Closed) {
      WebSocketHubLogger.warn("WebSocket已关闭，重连中");
    }

    try {
      // 创建新的 WSWrapperProxy（注意这里的类名是 WSWrapper，但实际导入的是 index.ts 导出的 WSWrapperProxy）
      ws = new WSWrapper(url, {
        getProtocols: this._optional?.getProtocols ?? undefined,
        getSocketUrl: this._optional?.getSocketUrl ?? undefined,
      });

      this.bindEventHandler(ws);                // 绑定事件处理器
      this._websockets[url] = ws;               // 存入映射表
    } catch (err) {
      WebSocketHubLogger.error("WebSocket创建失败", err);
    }
  }

  bindEventHandler：绑定事件处理器 (第 52-79 行)：
  private bindEventHandler(ws: WSWrapper) {
    // 消息事件
    ws.setOnMessage((...args) => this._onmessage?.call(ws, args[0]));

    // 打开事件
    ws.setOnOpen((...args) => this._onopen?.apply(ws));

    // 关闭事件（核心：自动重连逻辑）
    const self = this;
    ws.setOnClose(function (this: WSWrapper, url: string) {
      const onclose = self._onclose;

      if (onclose) {
        // 调用用户回调，传入 isExplicitlyClosed
        onclose.call(this, url, self._explicitlyClosed);
      }

      // 如果是手动关闭，不重连
      if (self._explicitlyClosed) {
        return;
      }

      // 自动重连逻辑
      if (self._autoConnect && url in self._websockets) {
        self.setReconnectTimeout(
          url,
          window.setTimeout(() => {
            self.assignWS(url);                 // 1.2秒后重新分配连接
          }, reconnectTimeout)
        );
      }
    });
  }

  trySend：发送消息 (第 115-128 行)：
  trySend(req: any, empty: any, force = false) {
    this.tryConnect();                          // 先确保连接存在

    const strReq = JSON.stringify(req);
    const strEmpty = JSON.stringify(empty);

    // 如果请求数据等于空数据，则关闭所有连接
    if (strReq === strEmpty) {
      this.tryClose();
    } else {
      // 向所有连接发送消息
      Object.values(this._websockets).forEach((ws) => ws.send(strReq, force));
    }
  }

  tryClose：手动关闭 (第 173-181 行)：
  tryClose() {
    this._explicitlyClosed = true;              // 标记为手动关闭
    this.clearReconnectTimeout();               // 清除所有重连定时器
    this._autoConnect = false;                  // 禁用自动重连

    for (const url in this._websockets) {
      this.closeWs(url);
    }
  }

  ---
  六、React Hook：useWebSocket

  文件：src/react/useWebSocket.ts

  完整代码分析：

  export default function useWebSocket(
    builder: URLBuilder,
    onmessage: UseWebSocketParamOnMessage | ((msg: MessageState) => void),
    optional?: WsOptional
  ) {
    const isUnmounted = useUnmounted()          // 检测组件是否卸载

    // 第 24-33 行：用 useState 创建 WebSocketHub 实例（只创建一次）
    const [wsObj] = useState<WebSocketHub>(() => {
      const hub = new WebSocketHub([], {
        getProtocols: optional?.getProtocols ?? undefined,
        getSocketUrl: optional?.getSocketUrl ?? undefined,
      });
      return hub;
    });

    // 第 37-38 行：用 ref 存储最新的发送参数
    const paramsTrySend = useRef<[req: any, empty: any, force?: boolean] | undefined>();
    const shouldTriggerTrySend = useRef(false); // 重连后是否需要重新发送

    const [wsTs, setWsTS] = useState<number>(0); // 时间戳（用于触发重渲染）

    // 第 43-53 行：包装 wsTrySend，加入卸载检查
    const wsTrySend = useCallback(
      function (req: any, empty: any, force = false) {
        if (isUnmounted()) return               // 卸载后不发送
        wsObj.trySend(req, empty, force);
      },
      [isUnmounted, wsObj]
    );

    // 第 56-70 行：劫持 wsObj.trySend，记录参数
    useEffect(() => {
      const originTrySend = wsObj.trySend;
      wsObj.trySend = function (
        this: WebSocketHub,
        ...args: Parameters<typeof originTrySend>
      ) {
        if (isUnmounted()) return
        paramsTrySend.current = args;           // 记录最新参数
        return originTrySend.call(wsObj, ...args);
      };
    }, [isUnmounted, wsObj]);

    const { addWSInstance, removeWSInstance } = usePseudoPingpong();

    // 第 74-77 行：当 builder 或 onmessage 变化时更新
    useEffect(() => {
      wsObj.setBuilder(builder);
      wsObj.setOnMessage(onmessage);
    }, [builder, onmessage, wsObj]);

    // 第 79-115 行：设置 onOpen 和 onClose 回调
    useEffect(() => {
      wsObj.setOnOpen(function onOpen() {
        if (isUnmounted()) return

        addWSInstance(this);                    // 添加到心跳检测
        setWsTS(getTimestamp());                // 更新时间戳触发重渲染

        // 如果是重连，重新发送之前的请求
        if (shouldTriggerTrySend.current && paramsTrySend.current) {
          wsObj.trySend(...paramsTrySend.current);
        }
        shouldTriggerTrySend.current = false;
      });

      wsObj.setOnClose(function onClose(url, isExplicitlyClosed) {
        if (isUnmounted()) return

        removeWSInstance(this);                 // 从心跳检测中移除
        setWsTS(getTimestamp());

        // 非手动关闭时，标记需要重连后重发
        if (!isExplicitlyClosed) {
          shouldTriggerTrySend.current = true;
        }
      });
    }, [addWSInstance, builder, isUnmounted, onmessage, removeWSInstance, wsObj]);

    // 第 117-123 行：组件卸载时关闭连接
    useEffect(() => {
      shouldTriggerTrySend.current = false;

      return () => {
        wsObj.tryClose();                       // 清理：关闭所有连接
      };
    }, [wsObj]);

    return {
      wsObj,
      wsTrySend,
      wsTs,                                     // @deprecated
    };
  }

  ---
  七、React Hook：useApiWebSocket

  文件：src/react/useApiWebSocket/index.ts

  在 useWebSocket 基础上，添加动态获取 WebSocket URL 的功能。

  export const useApiWebSocket = (
    onmessage: OnMyMessage,
    optional: {
      apiFetcher: ApiFetcher;                   // 用户提供的 API 获取函数
    } & WsOptional
  ) => {
    const isUnmounted = useUnmounted();
    const [initBuilder] = useState(() => []);   // 初始化为空数组

    // 第 26 行：存储用户调用 wsTrySend 时的参数
    const [sendData, setSendData] = useState<{ req: SendReqData; empty: any }>();

    // 使用 useWebSocket，传入空数组作为初始 builder
    const result = useWebSocket(initBuilder, onmessage, {
      getProtocols: optional.getProtocols,
      getSocketUrl: optional.getSocketUrl,
    });

    const apiFetcherRef = useRef(optional.apiFetcher);

    // 第 37-57 行：劫持 wsObj.trySend，捕获用户的请求参数
    useEffect(() => {
      const wsObj = result.wsObj;
      const originTrySend = wsObj.trySend;

      wsObj.trySend = (req: SendReqData, empty: any, force = false) => {
        // 只有当请求内容变化时才更新 sendData
        setSendData((sendData) => {
          if (!sendData?.req || JSON.stringify(sendData?.req) !== JSON.stringify(req)) {
            return { req, empty };
          }
          return sendData;
        });

        return originTrySend.call(wsObj, req, empty, force);
      };
    }, [result.wsObj]);

    // 第 59-111 行：当 sendData 变化时，获取 URL 并建立连接
    useEffect(() => {
      const wsObj = result.wsObj;
      const { req: reqData, empty: emptyData } = sendData || {};

      if (reqData == null) return;

      // 解析请求类型（device_id 或 type_path_code）
      const { type, data } = parseTypeData(reqData) || {};

      if (!type || !Array.isArray(data) || data.length === 0) return;

      const fetchData = async () => {
        if (isUnmounted()) return;

        try {
          // 调用用户提供的 API 获取 WebSocket URL 列表
          const builders = await getAvailableBuilders(apiFetcherRef.current)(type, data);

          if (isUnmounted()) throw new Error("stop to handle after leaving");

          // 更新 builder 并发送请求
          wsObj.setBuilder(Array.isArray(builders) ? builders : []);
          wsObj.trySend(reqData, emptyData, true);
        } catch (err) {
          UseApiWsLogger.debug("useApiWebSocket interval fetching failure");
        }
      };

      // 每分钟重新获取一次 URL
      let interval = window.setInterval(fetchData, fetchBuildersInterval);  // 60000ms

      // 首次立即执行
      fetchData();

      return () => {
        window.clearInterval(interval);
        interval = 0;
      };
    }, [isUnmounted, result.wsObj, sendData]);

    return result;
  };

  配合的 fetch.ts 解析：

  // 解析请求类型
  export const parseTypeData = (req: SendReqData): ParseTypeData => {
    if (SendReqDataKey.type_path_code in req) {
      return {
        type: "type_path_code",
        data: req[SendReqDataKey.type_path_code],
      };
    }

    if (SendReqDataKey.device_ids in req) {
      return {
        type: "device_id",
        data: req[SendReqDataKey.device_ids],
      };
    }

    return null;
  };

  // 调用 API 获取 WebSocket URL
  export const getAvailableBuilders =
    (apiFetcher: ApiFetcher) => async (type: DeviceType, typeData: string[]) => {
      // 根据类型构造请求体
      const data = getPartialPostData(type, typeData);
      // 例如：{ device_ids: ['d1', 'd2'] }

      // 调用用户提供的 API
      const { instances } = await apiFetcher(data);
      // 返回：['wss://server1/ws', 'wss://server2/ws']

      return instances;
    };

  ---
  八、心跳检测：usePseudoPingpong

  文件：src/react/usePseudoPingpong.ts

  每 10 秒向所有连接发送一次 ping 消息。

  const SOCKET_PINGPONG_TIMEOUT = 10 * 1000;    // 10秒

  export const usePseudoPingpong = () => {
    const isUnmounted = useUnmounted()

    const [delay, setDelay] = useState<number | null>(SOCKET_PINGPONG_TIMEOUT);
    const [instances, setInstances] = useState<WSWrapper[]>([]);  // 所有活跃连接

    // 添加连接到列表
    const addWSInstance = useCallback((newInstance: WSWrapper) => {
      if (isUnmounted()) return;

      setInstances((instances) => {
        // 检查是否已存在（通过引用或 URL）
        if (getArrayInstanceIndex(instances, newInstance) === -1) {
          const newInstances = instances.slice(0)
          newInstances.push(newInstance);
          return newInstances
        }
        return instances;
      });
    }, [isUnmounted]);

    // 从列表移除连接
    const removeWSInstance = useCallback((newInstance: WSWrapper) => {
      if (isUnmounted()) return;

      setInstances((instances) => {
        const idx = getArrayInstanceIndex(instances, newInstance);
        if (idx > -1) {
          const newInstances = instances.slice(0)
          newInstances.splice(idx, 1);
          return newInstances
        }
        return instances;
      });
    }, [isUnmounted]);

    // 执行 ping
    const doPing = useCallback(() => {
      if (isUnmounted()) return;

      instances.forEach((instance) => {
        instance.sendPingMessage();             // 重新发送上一条消息
      });
    }, [instances, isUnmounted]);

    // 使用 useHarmonicIntervalFn 定时执行
    useHarmonicIntervalFn(doPing, delay);

    return { addWSInstance, removeWSInstance, start, end };
  };

  sendPingMessage 的实现（在 WSWrapperProxy 中，第 238-246 行）：
  getPingMessage() {
    return this._lastMsg || "";                 // 返回上次发送的消息
  }

  sendPingMessage() {
    if (this._wsWrapper.sendable) {
      return this.sendMsg(this.getPingMessage(), true);  // force=true 强制发送
    }
  }

  ---
  九、Vue 版本差异

  useWebSocket（Vue 版）

  主要差异：

  1. 不使用 useState，直接创建实例：
  // Vue
  const wsObj = new WebSocketHub(unref(builder), { ... });

  // React
  const [wsObj] = useState<WebSocketHub>(() => new WebSocketHub([], { ... }));

  2. 使用 watch 而不是 useEffect 依赖数组：
  // Vue
  watch(
    () => unref(builder),
    (builder) => {
      wsObj.setBuilder(builder);
    }
  );

  // React
  useEffect(() => {
    wsObj.setBuilder(builder);
  }, [builder, wsObj]);

  3. 清理使用 onScopeDispose 而不是 useEffect return：
  // Vue
  if (getCurrentScope()) {
    onScopeDispose(function dispose() {
      wsObj.tryClose();
    });
  }

  // React
  useEffect(() => {
    return () => {
      wsObj.tryClose();
    };
  }, [wsObj]);

  4. 直接调用 tryConnect：
  // Vue：setup 时立即连接
  wsObj.tryConnect();

  // React：通过 useEffect 在适当时机连接

  ---
  十、完整数据流（以 React useApiWebSocket 为例）

  用户调用 wsTrySend({ device_ids: ['d1', 'd2'] }, {}, false)
      ↓
  useApiWebSocket 劫持的 trySend 被调用
      ↓
  setSendData({ req: { device_ids: ['d1', 'd2'] }, empty: {} })
      ↓
  useEffect 检测到 sendData 变化
      ↓
  parseTypeData 解析出 type='device_id', data=['d1', 'd2']
      ↓
  调用 getAvailableBuilders(apiFetcher)('device_id', ['d1', 'd2'])
      ↓
  apiFetcher 发起 HTTP 请求到后端 API
      ↓
  后端返回 { instances: ['wss://server1/ws', 'wss://server2/ws'] }
      ↓
  wsObj.setBuilder(['wss://server1/ws', 'wss://server2/ws'])
      ↓
  wsObj.trySend({ device_ids: ['d1', 'd2'] }, {}, true)
      ↓
  WebSocketHub.trySend 被调用
      ↓
  WebSocketHub.tryConnect() 被调用
      ↓
  getUrls() 返回 ['wss://server1/ws', 'wss://server2/ws']
      ↓
  对每个 URL 调用 assignWS(url)
      ↓
  创建 WSWrapperProxy('wss://server1/ws', ...)
      ↓
  WSWrapperProxy 内部创建 WSWrapper
      ↓
  WSWrapper 内部调用 getInstance(url, ...) 创建原生 WebSocket
      ↓
  原生 WebSocket 连接服务器
      ↓
  服务器接受连接，触发 ws.onopen
      ↓
  WSWrapper.onOpen 被调用，_state = WSState.Opened
      ↓
  WSWrapper.emit('open', ev)
      ↓
  WSWrapperProxy.setOnOpen 中的包装函数被调用
      ↓
  用户的 onOpen 回调被调用
      ↓
  flushSendBuffer() 被调用（此时缓冲区可能有待发消息）
      ↓
  WebSocketHub 遍历所有连接调用 ws.send(strReq, force)
      ↓
  WSWrapperProxy.send 被调用
      ↓
  throttleSendMsg 延迟 300ms 后调用 sendMsg_
      ↓
  sendMsg_ 检查通过后调用 this._wsWrapper.send(msg)
      ↓
  WSWrapper.send 调用 this._ws.send(msg)
      ↓
  原生 WebSocket 发送消息到服务器
      ↓
  服务器处理后推送设备状态
      ↓
  原生 WebSocket 触发 ws.onmessage
      ↓
  WSWrapper.onMessage 被调用
      ↓
  JSON.parse(data) 解析消息
      ↓
  WSWrapper.emit('message', d, ev)
      ↓
  WSWrapperProxy 的消息处理器被调用
      ↓
  WebSocketHub 的 _onmessage 被调用
      ↓
  用户提供的 onmessage 回调被调用
      ↓
  用户处理设备数据 { items: [...] }

  ---
  这个解释够详细吗？如果你想深入了解某个具体部分，告诉我。