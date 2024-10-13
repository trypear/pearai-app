import { useState } from 'react';
import { vscode } from "./utilities/vscode";
import { VSCodeButton, VSCodeCheckbox, VSCodeDivider } from "@vscode/webview-ui-toolkit/react";

interface AITool {
  name: string;
  enabled: boolean;
}

function App() {
  const [aiTools, setAiTools] = useState<AITool[]>([
    { name: "Perplexity", enabled: true },
    { name: "Continue", enabled: true },
    { name: "mem0", enabled: true },
    { name: "aider", enabled: true },
  ]);

  function handleToolToggle(index: number) {
    const updatedTools = [...aiTools];
    updatedTools[index].enabled = !updatedTools[index].enabled;
    setAiTools(updatedTools);

    vscode.postMessage({
      command: "updateAITools",
      tools: updatedTools,
    });
  }

  return (
    <main className="p-6 w-full h-full min-h-screen">
      <h1 className="text-3xl font-bold mb-6 text-[var(--vscode-foreground)]">PearAI Inventory</h1>
      <p className="mb-4 text-[var(--vscode-foreground)]">Select the AI tools you want to use in your code editor:</p>
      
      <div className="space-y-4">
        {aiTools.map((tool, index) => (
          <div key={tool.name} className="flex items-center justify-between p-4] border border-[var(--vscode-widget-border)] rounded-lg">
            <span className="text-lg text-[var(--vscode-foreground)]">{tool.name}</span>
            <VSCodeCheckbox checked={tool.enabled} onChange={() => handleToolToggle(index)}>
              {tool.enabled ? "Enabled" : "Disabled"}
            </VSCodeCheckbox>
          </div>
        ))}
      </div>

      <VSCodeDivider className="my-6" />

      <div className="flex justify-end">
        <VSCodeButton onClick={() => vscode.postMessage({ command: "saveInventory", text: "PearAI Inventory Saved!" })}>
          Save Inventory
        </VSCodeButton>
      </div>
    </main>
  );
}

export default App;