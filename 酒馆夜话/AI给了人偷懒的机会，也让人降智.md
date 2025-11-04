
First of all, I've decided to start writing articles in English so I can practice as often as possible. My goal is to rebuild my English writing skills to where they were five years ago. After writing in English, I'll use AI to translate these articles into Chinese—honestly, my Chinese writing isn't great either. But as a native Chinese speaker, communicating in Chinese comes so naturally that I don't get much practice actually _writing_ it carefully. I have to admit that these articles will all be edited by Claude again since my writing skills are already quite rusty

Claude Code has been bothering me lately, and I'm starting to understand why. It's not that the tool doesn't work—it's actually incredibly capable. The problem is more subtle: it's good enough to make me *think* I can relax, but not good enough to actually read my mind. There's always a gap—between what I mean and what I communicate, between what it assumes and what my codebase actually needs. And here's the thing about humans: we love taking shortcuts. When something seems to work automatically, we stop paying attention. We hit Enter without reading the plan, thinking we're saving time and mental energy. But we're not saving anything. We're just trading one kind of effort (careful review) for another kind (frantic debugging). We think we're being lazy, but we're actually making more work for ourselves—just later, when it's harder to fix.


首先说明一下，这篇文章是用英语写的，（然后 AI 再转一遍中文，虽然我的中文写作也不太好。）这样可以尽可能多地练习。我的目标是把英文写作能力恢复到五年前的水平（但也会用 AI 美化一下）

最近 Claude Code 一直困扰着我， 不是因为工具不好用——它其实非常强大。它好用到让我*以为* 可以偷懒，但又不足以真正读懂我的想法。总是有信息差——在我的意思和我 表达的内容之间，在它的假设和我代码库的实际需求之间。 而人类有个特点：喜欢走捷径。当某件事看起来能自动完成时，我们就不再专注了。我们不读计划就按回车，以为这样能省时间、省脑子。 但我们什么都没省下来。我们只是把一种努力（仔细审查）换成了另一种努力 （疯狂调试）。我们以为自己在偷懒，实际上是在给自己找更多的活——只是 推迟到了后面，那时候更难收拾。

---


**The Problem with Mindless Confirmation**

Here's something I've noticed: when I'm coding with Claude Code, I'm not always as focused as I should be.

For those unfamiliar, Claude Code has a "plan mode." When you submit a prompt, the AI agent generates a coding plan outlining how it intends to fulfill your requirements. You can review this plan and either approve it or reject it and provide different instructions. Since AI doesn't automatically know what we mean, we need to communicate as clearly as possible to bridge that gap between human intention and machine execution.

But here's my confession: I often don't carefully review the plan before pressing Enter. This mindless behavior requires almost no mental effort—it's disturbingly similar to scrolling through your phone. The action is effortless and automatic, which is exactly why it's so dangerous.


**无意识确认的问题**

我发现了一个现象：当我用 Claude Code 写代码时，我有时候会走神。

对不了解的人解释一下，Claude Code 有个"planmode"。当你提交提示后，AI 代理会生成一个编码计划，说明它打算如何完成你的需求。你可以检查这个计划，看看是否符合预期。我们需要尽可能清晰地和 AI沟通，来让彼此之间的认知差距减少。

但有时候我发现：我经常在按回车之前并没有仔细查看他所提供的计划。这种无意识的行为几乎不需要任何心智负担——他就和刷手机一样，一下子就搞定了，都意识不到这件事已经发生了

---


**The Hidden Cost**

When you don't check plans carefully, problems emerge later. You might discover that the generated code isn't what you wanted, or worse, that it's caused cascading issues. At that point, you've wasted far more time debugging than you would have spent on careful review or code by yourself.

I asked Claude if there was a logging tool to help me track these issues. It suggested `claude-code-log`, but after trying it, I realized I didn't need detailed step-by-step records—I needed high-level summaries after each major task. Too much detail just becomes overwhelming noise.


**隐藏的代价**

当你不仔细检查计划时，问题会在后面出现。你可能会发现生成的代码不是你想要的，或者更糟，它造成了连锁问题。到那时，你在调试上浪费的时间远远超过一开始仔细审查所需的时间。

我问 Claude 有没有日志工具可以帮我追踪这些问题。它推荐了 `claude-code-log`，但试用后我意识到，我不需要详细的步骤记录——我需要的是每个主要任务完成后的高层次总结。太多细节只会变成压倒性的噪音。

---


**What This Really Reveals**

What Claude Code has taught me isn't really about AI—it's about attention and intentionality. The tool is powerful, but its value depends entirely on how mindfully we use it. If we treat it like another dopamine-dispensing app, clicking through without thinking, we miss the point entirely.

This connects to something I've been reading about in _Peak: Secrets from the New Science of Expertise_ and _How to Break Up with Your Phone_. Both books emphasize the same fundamental truth: deep focus matters.  Real learning, real skill development—it all requires you to actually pay attention, not just skim the surface while your mind's somewhere else.

If we're accustomed to constant distraction, reluctant to think deeply or "waste time" absorbing information slowly and mindfully, can we truly understand anything at all?


**这真正揭示了什么**

Claude Code 教会我的其实不是关于 AI——而是关于注意力和意图性。工具很强大，但它的价值完全取决于我们多么用心地使用它。如果我们把它当成另一个分泌多巴胺的应用，不假思索地点击，我们就完全错过了重点。

这与我最近在读的《刻意练习》和《如何与手机分手》有关。两本书都强调同一个基本真理：深度专注很重要。真正的学习和技能发展需要持续的、刻意的注意力——而不是我们通过多年手机使用训练出来的碎片化、自动驾驶模式。

如果我们习惯于持续分心，不愿深入思考或"浪费时间"以缓慢而专注的方式吸收信息，我们真的能理解任何东西吗？

---


**The Choice**

Claude Code is just a tool—a mirror reflecting how we approach our work. If we bring mindfulness and intention, it amplifies our capabilities. If we bring our scrolling habits and fragmented attention, it just becomes another expensive distraction.

The choice, as always, is ours. 

**选择**

Claude Code 只是一个工具——一面反映我们如何对待工作的镜子。如果我们带来专注和意图，它会放大我们的能力。如果我们带来刷屏习惯和碎片化注意力，它就只是另一个昂贵的干扰。

选择，一如既往，在我们手中。

