import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';

export function activate(context: vscode.ExtensionContext) {
  console.log('PearAI Inventory extension is now active!');

  const disposable = vscode.commands.registerCommand('pearai-inventory.openInventory', () => {
    const panel = vscode.window.createWebviewPanel(
      'pearaiInventory',
      'PearAI Inventory',
      vscode.ViewColumn.One,
      {
        enableScripts: true,
        localResourceRoots: [vscode.Uri.file(path.join(context.extensionPath, 'dist'))]
      }
    );

    const htmlPath = path.join(context.extensionPath, 'dist', 'gui', 'index.html');

    if (fs.existsSync(htmlPath)) {
      let html = fs.readFileSync(htmlPath, 'utf-8');

      // Update the CSS and JavaScript file paths
      html = html.replace(/(href|src)="(.+?)"/g, (match, p1, p2) => {
        return `${p1}="${panel.webview.asWebviewUri(vscode.Uri.file(path.join(context.extensionPath, 'dist', 'gui', p2)))}"`;
      });

      panel.webview.html = html;
    } else {
      panel.webview.html = `
        <html>
          <body>
            <h1>PearAI Inventory</h1>
            <p>GUI not built yet. Please run 'yarn build-gui' in the extension directory.</p>
          </body>
        </html>
      `;
    }
  });

  context.subscriptions.push(disposable);
}

export function deactivate() {}


// // The module 'vscode' contains the VS Code extensibility API
// // Import the module and reference it with the alias vscode in your code below
// import * as vscode from "vscode";

// // This method is called when your extension is activated
// // Your extension is activated the very first time the command is executed
// export function activate(context: vscode.ExtensionContext) {
// 	// Use the console to output diagnostic information (console.log) and errors (console.error)
// 	// This line of code will only be executed once when your extension is activated
// 	console.log(
// 		'Congratulations, your extension "pearai-inventory" is now active!',
// 	);

// 	// The command has been defined in the package.json file
// 	// Now provide the implementation of the command with registerCommand
// 	// The commandId parameter must match the command field in package.json
// 	const disposable = vscode.commands.registerCommand(
// 		"pearai-inventory.helloWorld",
// 		() => {
// 			// The code you place here will be executed every time your command is executed
// 			// Display a message box to the user
// 			vscode.window.showInformationMessage(
// 				"asdfblahblahddHello World from pearai-inventory!",
// 			);
// 		},
// 	);

// 	context.subscriptions.push(disposable);
// }

// // This method is called when your extension is deactivated
// export function deactivate() {}


