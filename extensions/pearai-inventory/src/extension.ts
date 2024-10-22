import * as vscode from "vscode";
import { PearInventoryPanelTest } from "./panels/PearInventoryPanelTest";
import { commands } from "vscode";
import { PearInventoryPanel } from "./panels/PearInventoryPanel";

export class PearInventoryExtension {
	private outputChannel: vscode.OutputChannel;
	private pearInventoryPanel: PearInventoryPanel | null = null;

	constructor(
		private context: vscode.ExtensionContext,
		outputChannel: vscode.OutputChannel,
	) {
		this.outputChannel = outputChannel;
	}

	async activate() {
		this.outputChannel.appendLine("Pear activation started11=======================");

		this.pearInventoryPanel = new PearInventoryPanel(
			this.context.extensionUri,
			this.context,
		);

		this.context.subscriptions.push(
			vscode.window.registerWebviewViewProvider(
				"pearai.overlayWebview",
				this.pearInventoryPanel,
			),
		);

		outputChannel.appendLine("Pear Inventory extension activated!!");
		console.log("Pear Inventory extension activated!!!");
	}
	// TODO: Disposal needed?
	async deactivate(): Promise<void> {
		await this.pearInventoryPanel?.deactivate();
	}
}

let outputChannel: vscode.OutputChannel;
let extension: PearInventoryExtension;

export function activate(context: vscode.ExtensionContext) {
	console.log("Activating Pear extension!!!!!22");
	outputChannel = vscode.window.createOutputChannel("Pear");
	outputChannel.appendLine("Activating Pear extension!!");

	extension = new PearInventoryExtension(context, outputChannel);
	extension.activate();

	const showPearInventoryCommand = commands.registerCommand(
		"pearai-inventory.helloWorld",
		() => {
			PearInventoryPanelTest.render(context.extensionUri);
		},
	);

	console.log("Activating!");
	context.subscriptions.push(showPearInventoryCommand);
}

// TODO: Any disposal needed? Memory leaks?
export async function deactivate(): Promise<void> {
	console.log("Pear extension deactivated");
}
