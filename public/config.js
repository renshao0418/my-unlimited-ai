// public/config.js
// 仅用于前端 UI（模型下拉的显示），不包含任何敏感信息
// ⚠️ 本文件必须与 src/config.js 的 MODELS / DEFAULT_MODEL 保持同步
window.APP_MODELS = [
  { id: "google/diffusiongemma-26b-a4b-it", label: "diffusiongemma" },
  { id: "nvidia/llama-3.3-nemotron-super", label: "llama-3.3-nemotron-super" },
  { id: "moonshotai/kimi-k2.6", label: "kimi-k2.6" },
];
window.APP_DEFAULT_MODEL = "google/diffusiongemma-26b-a4b-it";
