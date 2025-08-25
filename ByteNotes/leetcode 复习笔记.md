## 滑动窗口Sliding Window
### 2461 长度为 k子数组的最大和 #leetcode-medium #leetcode-sliding-window 




### 2090 #leetcode-medium  
半径为 K 的子数组平均值
第一反应：维护一个数组arr 去记录 arr[i]，范围为长度为 2k 内 的 total
第二反应：并不需要一个数组，只需要一个滑动窗口，记录到 arr[i]当前为 k 半径内的总和就行，然后左侧出窗口，右侧进窗口
```Typescript
function getAverages(nums: number[], k: number): number[] {

let total = 0

const l = k * 2 + 1

const arr = new Array(nums.length).fill(-1)

for (let i = 0; i < nums.length; i++) {

total += nums[i]

if (i >= k * 2 && i - k >= 0 ) {

arr[i - k] = Math.floor(total / l )

console.log(i + 1 - l)

total -= nums[i + 1 - l]

}

}

console.log(arr)

return arr

};
```

一开始直接在 line 8 total / k，k=0 就挂了

### 2379  #leetcode-medium 
思路

> 滑动窗口，维护一个长度为 k 的窗口，计算在这个窗口内黑色块出现的最多次数，在不足长度 k 的时候让右侧区块进入判断区间，超过长度 k 时让右侧区块离开。 在这个窗口内出现黑色次数越多，需要替换成白色的次数越少

解题过程

> 在不足为 k 时，判断当前变量即可，看似进栈，不需要实际栈 时间复杂度： O(n)外层 for 循环遍历一次 blocks，长度为 n。 空间复杂度： O(1)主要用到到 res、total 这两个计数器以及少量临时变量。

##### 复杂度

- 时间复杂度: O(∗)O(*)O(∗)

- 空间复杂度: O(∗)O(*)O(∗)
```typescript
function minimumRecolors(blocks: string, k: number): number {

let res = 0;// max k times

let total = 0

for (let i = 0; i < blocks.length; i++) {

const cur = blocks[i]

total += cur === 'B' ? 1 : 0

if(i >= k) {

let left = blocks[i - k]

total -= left === 'B' ? 1 : 0

}

res = Math.max(total, res)

}

  

return k - res

};
```

### 2841 几乎唯一子数组的最大和 
#leetcode-medium
#leetcode-sliding-window

##### 思路
长度滑动窗口 + 计数哈希表
##### 解题过程
浪费空间维护数组没必要，最重要的是窗口左右两侧的数字是否是一个唯一数字。
维护一个当前窗口内不同数字的数量 diff，以及数字的出现次数 Map

窗口内的累计用一个 total 去维护
当右窗数字唯一，diff++，并计入 Map，记住他的出现次数
当窗口长度满足>=k时，需要移动左侧窗口
当左窗数字唯一diff--，Map 对应清零
total 的数据也要把左窗的数字去掉。

当 i从 0 走到 k 时，需要开始对左侧进行判断删减
在 diff 满足>=m 时，去判断最大值

##### 代码
```typescript
function maxSum(nums: number[], m: number, k: number): number {
    let res = 0;
    let diff = 0;
    let total = 0;

    const curM = new Map();

    for (let i = 0; i < nums.length; i++) {
        const cur = nums[i];
        let curTimes = curM.get(cur) ?? 0;
        curTimes === 0 && diff++;
        curM.set(cur, ++curTimes);

        total += cur;

        if (i >= k) {
            let prev = nums[i - k];
            let prevTimes = curM.get(prev);
            prevTimes === 1 && diff--;
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

##### 复杂度分析
时间复杂度

• 单个 for 遍历数组一次，长度为 n。

• 每步做有限次 Map.get/set 与常数级算术/比较操作（JS 的 Map 平均 O(1)）。

• ⇒ O(n)（均摊）。

空间复杂度

• 维护窗口内元素出现次数的 Map，最多只保存窗口大小 k 个不同值。

• 其余是常数级变量。

• ⇒ O(k)



