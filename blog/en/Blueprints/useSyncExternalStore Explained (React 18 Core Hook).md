# useSyncExternalStore Explained (React 18 Core Hook)

## 1. Code Architecture Diagram

```plaintext
┌─────────────────────────────────────────────────────────────┐
│                    Module-level Shared State                 │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  readSlugsSnapshot = Set<string>  ← Set of read article slugs ││
│  │  subscribers = Set<callback>      ← Subscriber list           ││
│  │  isInitialized = false            ← Whether initialized from localStorage ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                                ↑
           ┌────────────────────┼────────────────────┐
           │                    │                    │
      ┌────┴────┐          ┌────┴────┐          ┌────┴────┐
      │ Sidebar │          │ BlogPost│          │ Other   │
      │ Component│         │ Component│         │Components│
      └─────────┘          └─────────┘          └─────────┘
           │                    │
      useReadStatus()      useReadStatus()
           │                    │
           └────────────────────┴─── All components share the same state!
```

## 2. Why Use useSyncExternalStore?

### Background Problem (Drawbacks of Regular useState)

```tsx
// ❌ Problem: Each component has its own state copy
function Sidebar() {
  const [readSlugs, setReadSlugs] = useState(new Set()); // Copy A
}

function BlogPost() {
  const [readSlugs, setReadSlugs] = useState(new Set()); // Copy B
}
// Sidebar updates, BlogPost doesn't know!
```

### Solution (Shared External State)

```tsx
// ✅ All components share the same readSlugsSnapshot
let readSlugsSnapshot = new Set();  // Module-level variable, globally unique

function useReadStatus() {
  const readSlugs = useSyncExternalStore(
    subscribe,      // How to subscribe to changes
    getSnapshot,    // How to get current value
    getServerSnapshot  // Value during SSR
  );
}
```

## 3. Core Code Line-by-Line Analysis

### 1. Module-level Shared State (Lines 7-10)

```typescript
let readSlugsSnapshot: Set<string> = new Set();  // Stores read slugs
let isInitialized = false;                        // Prevents duplicate initialization
const subscribers = new Set<() => void>();        // Subscriber callbacks
```

> These variables are created once when the module loads, shared by all components.

### 2. Publish-Subscribe Pattern (Lines 13-39)

```typescript
// Notify all subscribers: "State changed!"
function emitChange() {
  subscribers.forEach((callback) => callback());
}

// Subscribe function: Called when component mounts
function subscribe(callback: () => void) {
  subscribers.add(callback);
  initializeFromStorage();  // Read from localStorage on first subscribe
  return () => subscribers.delete(callback);  // Return unsubscribe function
}
```

### 3. Mark as Read (Lines 53-69)

```typescript
function markAsRead(slug: string) {
  if (readSlugsSnapshot.has(slug)) return;  // Skip if already read

  // ⚠️ Key: Create new Set, don't just .add()
  const next = new Set(readSlugsSnapshot);
  next.add(slug);
  readSlugsSnapshot = next;  // Replace reference

  localStorage.setItem(...);  // Persist
  emitChange();  // Notify all subscribers to re-render
}
```

> Why create a new Set? React uses reference comparison to determine if updates are needed. If you only .add(), the reference doesn't change, React thinks nothing changed.

### 4. SSR Handling (Lines 47-50, 82-86)

```typescript
const emptySet = new Set<string>();
function getServerSnapshot() {
  return emptySet;  // Return empty Set during SSR
}

// In Hook
const isRead = useCallback((slug: string): boolean => {
  if (!isInitialized) return true;  // Default "read" during SSR, don't show new tag
  return readSlugs.has(slug);
}, [readSlugs]);
```

> Why return true during SSR? To avoid hydration mismatch:
> 
> - Server: Doesn't know localStorage, can't determine
> - Client: Knows localStorage
> - If returning different values, React will report hydration error

## 4. Data Flow Diagram

```plaintext
User clicks article
        │
        ▼
  markAsRead("some-slug")
        │
        ▼
  ┌─────────────────────────────┐
  │ 1. Create new Set (immutable update) │
  │ 2. Save to localStorage             │
  │ 3. emitChange() notify subscribers  │
  └─────────────────────────────┘
        │
        ▼ (All subscriber callbacks are called)
        │
  ┌─────┴─────┐
  ▼           ▼
  Sidebar    Other components
  re-render  re-render
```

## 5. Usage Example (SideBar.tsx Line 175)

```tsx
// Only show "new" tag if updated within 7 days AND unread
{isWithinDays(file.updatedAt, 7) && !isRead(file.path) && (
  <span className="... bg-orange-100 text-orange-600 ...">
    new
  </span>
)}
```

## 6. Summary: Why Write It This Way?

| Requirement | Solution |
|-------------|----------|
| Share state across components | Module-level variable + useSyncExternalStore |
| Persistence | localStorage |
| Avoid hydration errors | Return default value during SSR |
| Trigger React updates | Immutable updates (create new Set) |
