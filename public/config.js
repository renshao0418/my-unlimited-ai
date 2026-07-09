// public/config.js
// 仅用于前端 UI（模型下拉的显示），不包含任何敏感信息
// ⚠️ 本文件必须与 src/config.js 的 MODELS / DEFAULT_MODEL 保持同步
window.APP_MODELS = [
  { id: "google/diffusiongemma-26b-a4b-it", label: "gemma" },
  { id: "nvidia/llama-3.3-nemotron-super", label: "llama-3.3-nemotron-super" },
  { id: "z-ai/glm-5.2", label: "glm-5.2" },
  { id: "mistralai/mistral-small-4-1193-2603", label: "mistral-small-4" },
];
window.APP_DEFAULT_MODEL = "google/diffusiongemma-26b-a4b-it";
