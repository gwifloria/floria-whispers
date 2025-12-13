# Recent Claude Code Pitfalls Summary

### First Pitfall: Type Definitions Duplicated Everywhere

I have a full-stack Monorepo project where API types should theoretically be shared. But when I asked Claude Code to build a complete frontend-backend feature, it generated separate type definitions for frontend and backend.

What problems did this cause? When requirements changed later, I had to modify multiple places, and AI often missed some.

Later I agreed on a convention with it: **Define a core CoreType in a shared package, and frontend/backend each inherit and add their own fields.**

But I made a mistake here—I didn't immediately write this convention into `CLAUDE.md`, and similar issues appeared again a few days later when AI forgot.

---

### Second Pitfall: Works Locally, Breaks on Deploy

When merging Express and Next.js into Turborepo, I told AI I wanted to deploy some long-running services separately, like email sync and API polling.

AI appeared to finish the work, and local tests all passed. But problems arose after deployment—it wrote the email sync logic in Next.js API Routes.

What's the problem? My frontend is deployed on Vercel, which is a Serverless environment with **function execution time limits that don't support long connections**. These long-running tasks simply can't run there.

Later I migrated these services to a standalone Node service on Render to solve it.

---

### Third Pitfall: Mindlessly Retrying on Errors

Once a build failed, AI ran `yarn build` and got an error saying `dist/` directory doesn't exist. Then it started **retrying the same command repeatedly**, four or five times, same error each time.

It doesn't stop to analyze: why doesn't the dist directory exist after build? Did the build itself fail? It just mechanically repeats until I interrupt it.

---

### Fourth Pitfall: Treating Symptoms, Not Seeing the Big Picture

Another time Render deployment failed, with an error saying `sharp` needs `node-gyp`. AI's first reaction was to add `node-gyp` as a dependency in the root directory.

I remember sharp is for image optimization, and the service being deployed to Render doesn't need it.

I asked one question: "Why does the backend service need sharp?"

It checked and discovered: **the backend service doesn't need it at all**. The real problem was that `yarn install` in `render.yaml` installs the entire Monorepo's dependencies, and should be changed to install only what the service needs.

This is typical **treating symptoms**—it sees an error and thinks about how to eliminate that error, rather than stepping back to think about why this dependency is appearing here.

Also adding a point that some features could combine CSR and SSR, which also needs human-led design decisions.

---

### Fifth Pitfall: Using "Lazy Solutions" to Bypass Problems

AI has two dangerous habits:

**First is disabling ESLint errors.** For example, when `exhaustive-deps` warns, instead of analyzing how the dependency array should be written, it just adds `eslint-disable-next-line` and calls it done. Code runs, but issues are buried.

**Second is hardcoding sensitive information to make builds pass.** For example, when environment variables aren't configured, builds will fail, so it writes the token directly in code as a fallback. The correct approach should be to check environment variables at build time and fail if missing, not to hide behind default values.

Third is when test cases don't pass, it goes to directly modify the test cases...

---

### My Reflection

These pitfalls appear to be AI's problems on the surface, but thinking in reverse, **the core issue is actually that I didn't communicate context clearly.**

The most critical thing for using AI well is to provide your context to it as gap-free as possible—requirements background, technical constraints, deployment environment—things you think are "obviously evident," but AI doesn't know.

And **"organizing context" itself is a skill** that I think many people aren't very good at, including myself. The pitfalls I hit earlier were essentially me not making implicit knowledge explicit—not clearly stating the deployment environment is Serverless, not promptly documenting conventions.

This skill isn't just needed for working with AI, it's the same when working with people. I'm still deliberately practicing in this area, like now I record my thinking process, decisions made, and pitfalls encountered. This way, whether for AI or my future self, the context is more complete.

---

Now my AI at least really understands me when it comes to UI design.
