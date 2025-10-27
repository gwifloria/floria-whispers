## 双指针？
1493
```typescript
function longestSubarray(nums: number[]): number {

let left = 0;

let ans = 0

let cnt = 0

for (let right = 0; right < nums.length; right++) {

cnt += 1 - nums[right]

while (cnt > 1) {

cnt-= 1 - nums[left]

left ++

}

ans = Math.max(ans, right - left)

}

return ans

};
```
## **滑动窗口 Sliding Window**
### **3无重复字符的最长子串**
这题以前做过，直接暴力用了两个 while，时间复杂度和空间复杂度都是 O（n)
```typescript
function lengthOfLongestSubstring(s: string): number {

let ans = 0

let left = 0

const m = new Map()

for (let right = 0; right < s.length; right++ ) {

if(m.has(s[right]) && m.get(s[right]) >= left){

left = m.get(s[right]) + 1

}

m.set(s[right], right)

ans = Math.max(ans, right - left + 1)

}

return ans

};
```

### **3652按策略买卖股票的最佳时机**
1. 前缀和
计算[i, i + k] 的 delta 变化
维护两个前缀和数组，一个数组是策略前缀和，一个数组是纯 price 前缀和
```typescript
function maxProfit(prices: number[], strategy: number[], k: number): number {

	const n = prices.length
	
	const sumPrefix = new Array(n + 1).fill(0)
	
	const pricePrefix = new Array(n + 1).fill(0)
	
	let max = 0

	for (let i = 0; i < n; i++ ){
	
		sumPrefix[i + 1] = sumPrefix[i] + prices[i] * strategy[i]
		
		pricePrefix[i + 1] = prices[i] + pricePrefix[i]
	
	}

	for (let i = 0 ; i <= n - k; i ++ ){
	
		const diffSufHalf = pricePrefix[i + k] - pricePrefix[i + k/2] - (sumPrefix[i + k] - sumPrefix[i + k/2])
		
		  
		
		const diffPreHalf = - (sumPrefix[i + k/2] - sumPrefix[i])
		
		const delata = diffSufHalf + diffPreHalf
		
		max = Math.max(delata, max)
	
	}

	return sumPrefix[n] + max

};
```

2. 滑窗
虽然前缀和容易，滑窗没那么好写，但是感觉比起leetcode 上面的刷题数目，不如好好吃透一题

### **1052爱生气的书店老板**
 没做出来，看的灵神解析
 统计不生气时的顾客数量，以及找到固定窗口长度内不生气的顾客数量的最大值
```typescript
/*

* @lc app=leetcode.cn id=1052 lang=javascript

*

* [1052] 爱生气的书店老板

*/

  

// @lc code=start

/**

* @param {number[]} customers

* @param {number[]} grumpy

* @param {number} minutes

* @return {number}

*/

  
  

var maxSatisfied = function (customers, grumpy, minutes) {

let res = 0

let notAngrySum = 0

let curWindowAngrySum = 0

for (let i = 0 ; i < customers.length ; i++) {

notAngrySum += grumpy[i] === 0 ? customers[i] : 0

curWindowAngrySum += customers[i] * grumpy[i]

if (i < minutes - 1) {

continue

}

res = Math.max(curWindowAngrySum, res)

curWindowAngrySum -= customers[i - minutes + 1] * grumpy[i - minutes + 1]

}

return notAngrySum + res

};

// @lc code=end
```


### **2461. 长度为 k 子数组的最大和**

#leetcode-medium #leetcode-sliding-window

---

### **2090. 半径为 K 的子数组平均值**
#leetcode-medium

**思路**

- 第一反应：维护一个数组 arr 去记录 arr[i]，范围为长度为 2k 内的 total。
    
- 第二反应：并不需要一个数组，只需要一个滑动窗口，记录当前为 k 半径内的总和就行。左侧出窗口，右侧进窗口。
    

```
function getAverages(nums: number[], k: number): number[] {
  let total = 0;
  const l = k * 2 + 1;
  const arr = new Array(nums.length).fill(-1);

  for (let i = 0; i < nums.length; i++) {
    total += nums[i];

    if (i >= k * 2 && i - k >= 0) {
      arr[i - k] = Math.floor(total / l);
      total -= nums[i + 1 - l];
    }
  }

  return arr;
}
```

⚠️ 一开始直接在 line 8 写 total / k，k=0 就挂了。

---

### **2379. 得到 K 个黑块的最少涂色次数**

#leetcode-medium

**思路**

滑动窗口，维护一个长度为 k 的窗口，计算窗口内黑色块出现的最多次数。

- 不足 k 时：右侧区块进入判断区间；
    
- 超过 k 时：左侧区块离开；
    
- 在窗口内黑色次数越多，需要替换的次数越少。
    

  

**解题过程**

- 不足 k 时只需判断当前变量，看似进栈但无需实际栈。
    
- 时间复杂度：O(n)，一次遍历 blocks；
    
- 空间复杂度：O(1)，仅用到 res、total 计数器和少量变量。
    

```
function minimumRecolors(blocks: string, k: number): number {
  let res = 0; // max k times
  let total = 0;

  for (let i = 0; i < blocks.length; i++) {
    const cur = blocks[i];
    total += cur === "B" ? 1 : 0;

    if (i >= k) {
      let left = blocks[i - k];
      total -= left === "B" ? 1 : 0;
    }

    res = Math.max(total, res);
  }

  return k - res;
}
```

---

### **2841. 几乎唯一子数组的最大和**

#leetcode-medium #leetcode-sliding-window

**思路**

- 长度滑动窗口 + 计数哈希表
    
- 窗口内维护累计和 total，以及元素出现次数 Map
    
- 用 diff 表示当前窗口内不同数字的数量
    
- 窗口长度达到 k 时，左侧元素需要移出
    

**解题过程**

- 当右窗数字第一次出现 → diff++，加入 Map
    
- 当左窗数字被移出且只剩 1 个时 → diff--，Map 对应清零
    
- 每次窗口长度达到 k 时，若 diff >= m，则更新最大和
    

```
function maxSum(nums: number[], m: number, k: number): number {
  let res = 0;
  let diff = 0;
  let total = 0;

  const curM = new Map();

  for (let i = 0; i < nums.length; i++) {
    const cur = nums[i];
    let curTimes = curM.get(cur) ?? 0;
    if (curTimes === 0) diff++;
    curM.set(cur, ++curTimes);

    total += cur;

    if (i >= k) {
      let prev = nums[i - k];
      let prevTimes = curM.get(prev);
      if (prevTimes === 1) diff--;
      curM.set(prev, --prevTimes);
      total -= prev;
    }

    if (diff >= m) {
      res = Math.max(total, res);
    }
  }

  return res;
}
```

**复杂度分析**

- 时间复杂度：O(n)，单次遍历数组，每步操作为常数或 Map 的均摊 O(1)。
    
- 空间复杂度：O(k)，Map 至多存储窗口大小的元素。
    
