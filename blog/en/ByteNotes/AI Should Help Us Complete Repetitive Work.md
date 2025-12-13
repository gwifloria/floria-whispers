---
status: draft
type: Workshop
language: EN
---

# AI Should Help Us Complete Repetitive Work

## I Built a Markdown → WeChat Article Formatting Tool with Claude Code

> Built a Markdown → HTML tool, one-click copy to WeChat Official Account. Open-sourced, feel free to use.

https://www.gwifloria.space/tools/md-to-wechat

### Pain Point: The Gap Between Markdown and WeChat Official Account

Last week I spent half an hour adjusting formatting in the WeChat backend, then suddenly realized: why can't this repetitive work be automated?

I'm used to writing in Markdown, and Obsidian has always been my writing tool. But WeChat Official Account doesn't support Markdown format, and every time I copy over, I need to manually adjust the layout.

**Tried existing tools, but none were ideal:**
- Required login or payment
- Complex configuration, high learning curve
- As a beginner, I didn't know what paragraph spacing or font size should be

**Manual adjustment? Even more troublesome:**
- Need to readjust every time I publish, typical repetitive work
- Although WeChat has template features, initializing templates still requires DIY
- And I worried: what if I get tired of the same template? Would adjusting it add mental burden and make me not want to publish at all?

Rather than searching for articles to use as template references, why not let AI directly generate a decent version.

**So I spent an afternoon having Claude Code write me a Markdown to HTML interface, one-click copy ready to use.**

> Side note: My Xiaohongshu hasn't kept up with WeChat Official Account updates because I'm too lazy to make collages. Hope to fill this "efficient Xiaohongshu posting" gap in the future.

---

### Approach: Let AI Handle Format Conversion

These days I like to throw many trivial tasks to AI, especially when Markdown formatting adjustments are needed.

So I had Claude Code write a Markdown → HTML conversion tool, so I can one-click copy the styles I need, instead of repeatedly operating in the backend editor.

Since my personal website already has Markdown display functionality, the development cost was relatively low.

**Core Features:**
1. Paste Markdown on the left, real-time HTML preview on the right
2. Several preset themes to switch between
3. One-click copy, paste directly into WeChat Official Account backend

---

### Usage Flow

#### 1. Copy Markdown from Obsidian

#### 2. Select Theme (Optional)

#### 3. Copy to WeChat Editor

### Some Notes

**Markdown Writing Suggestions:**
- Don't nest lists too deep (WeChat support is limited)
- Code blocks recommended ≤ 20 lines
- Images need to be uploaded separately
- Check links and bold text after pasting

---

### The Meaning of Tools: Spend Time on Creating

This tool made me realize: what AI should help us do most is repetitive, mechanical work—like format conversion and style adjustment.

But the core of writing (conception, expression, emotion) still needs to come from ourselves. Tools just clear obstacles, letting me focus on what really matters.

---

### Open Source

Tool code is open-sourced, included in my personal website project:
- Personal website: https://www.gwifloria.space/
- GitHub: [Project link] (if available)

Feel free to use directly, PRs and suggestions welcome.

---

### Final Words: Find a Reason to Build Something

Recently noticed some people around me want to try vibecoding but don't know where to start.

My experience is: **don't overthink it, just start from your own pain points.**

Like this tool, it started just because "I don't want to manually adjust formatting every time." Keep taking in new things, stay curious, and you'll always find something you want to express or solve.

If you have similar small frustrations, try having AI help you build a small tool. Maybe an afternoon can solve something that's been bothering you for a long time.
