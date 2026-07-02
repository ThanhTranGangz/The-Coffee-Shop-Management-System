Windows (PowerShell) environment.

- Build WAR: `ant dist` (from project root; wraps NetBeans-generated `nbproject/build-impl.xml`). Output goes to `dist/`, intermediate compiled classes to `build/` — both gitignored.
- No test runner configured (`test/` dir doesn't exist) — do not look for/invoke `ant test`.
- No package-manager install step (no `npm install`/`mvn install`) — dependencies are the jars already committed in `lib/`.
- Normal file search/read/edit should go through Serena's tools per `mem:memory_maintenance`; only use Glob/Grep for name-based discovery.
- DB is SQL Server, not something startable via a simple CLI here — historically started via `brew services start mssql-server` on the original Mac dev machine (see `mem:core` caveat about `HUONG_DAN_TRUY_CAP.md` being stale); on this Windows machine, verify how SQL Server is actually being run before assuming that command applies.
