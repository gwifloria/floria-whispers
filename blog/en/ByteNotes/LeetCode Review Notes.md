

## [3634. Minimum Removals to Balance Array](https://leetcode.cn/problems/minimum-removals-to-balance-array/)
The data to be removed must be the maximum or minimum, so prioritize sorting by size and remove from both ends.
Finally, we want the minimum number of deletions, so we calculate a maximum window.

## [1493. Longest Subarray of 1's After Deleting One Element](https://leetcode.cn/problems/longest-subarray-of-1s-after-deleting-one-element/)

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

## **Sliding Window**

### **3. Longest Substring Without Repeating Characters**
Did this before, directly used two whiles brute force, time and space complexity both O(n)

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

### **3652. Best Time to Buy and Sell Stock by Strategy**

1. Prefix Sum
Calculate delta change for [i, i + k]
Maintain two prefix sum arrays, one for strategy prefix sum, one for pure price prefix sum

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

2. Sliding Window
Although prefix sum is easier, sliding window isn't as easy to write, but I feel compared to the number of problems on LeetCode, better to thoroughly understand one problem.

### **1052. Grumpy Bookstore Owner**
Didn't solve it, looked at solution analysis.
Count the number of customers when not grumpy, and find the maximum number of grumpy customers within a fixed window length.

```typescript
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
```

### **2461. Maximum Sum of Distinct Subarrays With Length K**

#leetcode-medium #leetcode-sliding-window

---

### **2090. K Radius Subarray Averages**
#leetcode-medium

**Approach**
- First reaction: Maintain an array arr to record arr[i], within a range of length 2k total.
- Second reaction: Don't need an array, just need a sliding window to record the total within radius k. Left side exits window, right side enters window.

```typescript
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

⚠️ Initially wrote total / k directly on line 8, failed when k=0.

---

### **2379. Minimum Recolors to Get K Consecutive Black Blocks**

#leetcode-medium

**Approach**
Sliding window, maintain a window of length k, calculate the maximum occurrences of black blocks within the window.

- Below k: Right side block enters judgment range
- Above k: Left side block exits
- More black blocks in window means fewer replacements needed

```typescript
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

### **2841. Maximum Sum of Almost Unique Subarrays**

#leetcode-medium #leetcode-sliding-window

**Approach**
- Length sliding window + counting hash map
- Maintain cumulative sum total and element occurrence count Map within window
- Use diff to represent number of distinct numbers in current window
- When window length reaches k, left element needs to exit

```typescript
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

**Complexity Analysis**
- Time complexity: O(n), single array traversal, each operation is constant or amortized O(1) for Map
- Space complexity: O(k), Map stores at most window size elements
