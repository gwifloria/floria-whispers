2090 半径为 K 的子数组平均值
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

## 2379 
