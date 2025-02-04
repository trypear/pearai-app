import { Codicon } from '../../../../base/common/codicons.js';
import { Disposable } from '../../../../base/common/lifecycle.js';
import { ICommandService } from '../../../../platform/commands/common/commands.js';
import { EventType, addDisposableListener } from '../../../../base/browser/dom.js';

export class AuxiliaryTitleBar extends Disposable {
    private container: HTMLElement;
    private readonly iconLabels = [
        { icon: Codicon.layoutPanel, title: 'Toggle Panel', command: 'workbench.action.togglePanel' },
        { icon: Codicon.layoutSidebarRight, title: 'Toggle PearAI  Sidebar', command: 'workbench.action.toggleAuxiliaryBar' },
        { icon: Codicon.layoutCentered, title: 'Toggle Centered Layout', command: 'workbench.action.toggleCenteredLayout' },
    ];

    constructor(
        parent: HTMLElement,
        @ICommandService private readonly commandService: ICommandService
    ) {
        super();

        // Create the title bar container
        this.container = document.createElement('div');
        this.container.classList.add('auxiliary-custom-titlebar');

        // Insert at the beginning of the parent
        parent.insertBefore(this.container, parent.firstChild);

        this.renderIcons();
    }

    private renderIcons(): void {
        this.iconLabels.forEach(({ icon, title, command }) => {
            const button = document.createElement('button');
            button.classList.add('monaco-button', 'codicon', `codicon-${icon.id}`);
            button.title = title;

            this._register(addDisposableListener(button, EventType.CLICK, () => {
                this.commandService.executeCommand(command);
            }));

            this.container.appendChild(button);
        });
    }

    override dispose(): void {
        super.dispose();
        this.container.remove();
    }
}
