This year, I have been experimenting with various AI programming tools to assist me in writing code.  
After subscribing to Copilot and GPT-5, I eventually chose ClaudeCode as my long-term companion.

Its _Plan Mode_ has proved remarkable — it embodies a refined philosophy of software creation:  
**plan in as much detail as possible before writing the very first line.**

Yet, unexpectedly, a new problem emerged.  
When ClaudeCode is fully engaged in the process, I often find myself at a loss — uncertain what to do while it works.  
More often than not, I end up idly scrolling through my phone, drifting from one app to another.

No matter whether it’s AI tools or human beings, when we receive a set of requirements or a production file, we should both take time to think deeply:

1. to understand the true intent behind the demands,
    
2. and to explore possible solutions to the problems.
    

Many would say that while waiting for AI to finish its work, we can grab a coffee, have a cup of tea, or simply do something else.  
But do we really have that much to do?  
How many cups of coffee can we drink in a day?

AI is supposed to enhance our efficiency — but has it, really?  
More and more people spend their “saved time” scrolling through social media.  
When we rely too heavily on AI, are we becoming smarter, or duller?

Social media and shortcuts have stolen much of our attention — and with it, our ability to think deeply.  
We are flooded with information we don’t truly need.  
So how can we reclaim the initiative — to **lead our own thoughts**, rather than being **led and shaped** by the very tools we created?

ClaudeCode comes equipped with a _hooks_ feature that allows users to develop or configure personalized functions — such as custom notifications.  
However, I believe that for many people, their devices are permanently muted.

So what inspired me?  
When I was using ClashX, the constantly flashing upload and download statistics often distracted me from focusing on my actual work.  
That led me to wonder: **shouldn’t AI distract me from surfing the internet — and instead, help me refocus on the tasks I asked it to do?**  
When it finishes its job, that’s the moment for me to step back in and give the next instruction.
### 💡 Proposed Solution

- **When ClaudeCode is working** (e.g. searching, writing, or editing):  
    SwiftBar displays a subtle loading animation to indicate that the process is in progress.  
    After the user submits a prompt, there’s no need to switch rapidly to the terminal just to check its status.
    
- **When ClaudeCode is waiting for user confirmation** before executing potentially risky actions:  
    The _notification hook_ is triggered to alert the user, and SwiftBar shows a ⚠️ symbol.
    
- **When a task is completed:**  
    SwiftBar displays a ✅ to notify the user that the job is done — it’s time to review the results.

| 图标     | 状态                   | 描述                                                                              |
| ------ | -------------------- | ------------------------------------------------------------------------------- |
| ⚠️     | **needs attention ** | s waiting for users' confirmation before some dangerous steps(highest priority) |
| ⠇⠦⠴⠸⠙⠋ | **in progress**      |                                                                                 |
| ✅      | **completed**        | Check The Job                                                                   |
| 💤     | **idle**             | waiting for orders                                                              |
|        |                      |                                                                                 |

