

> Based on actual development work experience comparison

## Overall Rating Overview

| Feature | GPT5 | Claude Code |
|---------|------|-------------|
| Instruction Understanding | Requires clear and specific instructions | Better context understanding |
| Response Speed | Slower, fragmented waiting time | Relatively faster |
| Code Quality | Tends to overdo things, requires frequent corrections | Has inherent biases for specific tech stacks |
| Workflow | Suitable for fixing small page bugs and styles | Better suited for overall feature development |

---

## GPT5 User Experience

### Advantages
- **After using CC, can't think of any**
- Now prefer using the free version
	- Shallow modifications to specific files for styles, save money
	- Ask fragmented questions or help organize md format

### Pain Points and Issues

#### 1. Response Experience Issues
**Problem**: After building project code, response speed gets slower and slower, and CPU usage becomes extremely high
**Impact**:
- Relatively slower response speed
- Fragmented waiting time, with high CPU usage the computer can't be used for other things, recently keeping a book in front of me, better than scrolling phone

#### 2. Code Quality
**React Hooks Issues**:
- Often places hooks after conditional statements
- Repeats the same mistakes even after multiple reminders

#### 3. Information Accuracy Issues
**Microsoft 365 E5 Developer Registration Case**:
- When implementing Outlook email fetching, GPT5 suggested registering for an E5 developer account
- When I explicitly asked about regional (mainland China) restrictions, it told me mainland is accessible
- Later I searched other forums and found this sandbox is disabled in mainland China
- When asked again later, it changed its story saying it's not feasible

**Summary**: Tends to provide inaccurate or outdated information

### Use Cases
- Clear, specific development tasks
- Repetitive work that doesn't require exploration
- Code generation that needs to follow strict standards

---

## Claude Code User Experience

### Advantages
- `/planmode` feature helps with project planning, after careful planning, you can let go and think about the next complete feature
- Interruptible, when current task execution deviates from expectations, can press esc to stop

### Pain Points and Issues

#### 1. Tech Stack Bias Issues
**Next.js Image Component Issues**:
- When introducing Image component, defaults to `/img` path
- After correcting to proper `Image`, prioritizes using deprecated attributes
- Has ingrained incorrect preferences for specific tech stacks

#### 2. Interaction Style Issues
**Overly Cautious**:
- Conversation style is too cautious and verbose
- Tends to avoid problems rather than solve them

**Real Case - DNS Configuration Issue**:
- When encountering network configuration issues
- Obvious DNS pollution needs to be resolved
- But tends to suggest workarounds rather than root solutions
- Spends lots of text persuading to avoid solving the root problem

#### 3. Development Process Advantages
**Value of Plan Mode**:
- Forces thinking before development
- Helps sort out overall flow
- Clarifies priorities and potential issues
- More effective than just starting to code

### Use Cases
- Complex tasks requiring project planning
- Exploratory development work
- Requirements needing repeated discussion and adjustment

---

### General Notes
1. **Timely Verification**: Regardless of which tool you use, always verify generated code and information promptly
2. **Stay Proactive**: Avoid over-reliance, maintain independent thinking and documentation habits
3. **Staged Confirmation**: Confirm after completing each feature point, avoid accumulating problems

---

## Personal Summary

Both tools have their advantages and limitations, the key is:
1. Choose the appropriate tool based on task characteristics
2. Maintain critical thinking about generated content
3. Don't completely rely on AI, maintain technical judgment
4. Use AI as an auxiliary tool rather than a replacement

5. Give clear instructions as much as possible, GPT isn't your brain after all, some details may already exist in your mind by default, you might not even remember to tell the other party. Everyone's definition of "beautiful" and "cute" is different, need to provide objective descriptions, not abstract words

AI tools are like a collective knowledge graph of today's world, but how to connect specifically still requires you to give commands to form your own knowledge graph

*Most importantly, maintain the ability to learn new technologies and solve problems, rather than letting AI become a substitute for thinking.*

Both will do stupid things: like displaying my GitHub secrets concatenated into frontend URLs
Although using Tailwind, always writes classname multiple times, parent has text styles, child elements write them again
This always affects parsing
