
import { vscode } from "./utilities/vscode";
import { VSCodeButton } from "@vscode/webview-ui-toolkit/react";

function App() {
	function handleHowdyClick() {
	  vscode.postMessage({
		command: "hello",
		text: "Hey there partner! 🤠",
	  });
	}
  
	return (
  <main className="p-4 border border-gray-300 rounded-lg">
    <h1 className="text-2xl font-bold mb-4">Hello World!</h1>
    <div className="border border-gray-300 p-4 rounded-lg">
		<VSCodeButton onClick={handleHowdyClick}>Howdy!</VSCodeButton>
    </div>
	  </main>
	);
  }

export default App;
