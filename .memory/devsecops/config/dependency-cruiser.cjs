module.exports = {
  forbidden: [
    { name: "no-circular", severity: "error", from: {}, to: { circular: true } },
    { name: "no-orphans", severity: "info", from: { orphan: true, pathNot: "\\.d\\.ts$" }, to: {} },
  ],
  options: { doNotFollow: { path: "node_modules" }, tsPreCompilationDeps: true },
};
