import { IViewPaneOptions, ViewPane } from '../../../../workbench/browser/parts/views/viewPane'
import { IInstantiationService } from '../../../../platform/instantiation/common/instantiation'
import { IViewDescriptorService } from '../../../../workbench/common/views'
import { IKeybindingService } from '../../../../platform/keybinding/common/keybinding'
import { IContextMenuService } from '../../../../platform/contextview/browser/contextView'
import { IConfigurationService } from '../../../../platform/configuration/common/configuration'
import { IContextKeyService } from '../../../../platform/contextkey/common/contextkey'
import { IOpenerService } from '../../../../platform/opener/common/opener'
import { ITelemetryService } from '../../../../platform/telemetry/common/telemetry'
import { IThemeService } from '../../../../platform/theme/common/themeService'
import { IHoverService } from '../../../../platform/hover/browser/hover'
import { mountPearAI } from './react/out/index.js'
import { IDisposable } from '../../../../base/common/lifecycle'

export class PearAIPane extends ViewPane {
  static readonly ID = 'pearai.view';

  constructor(
    options: IViewPaneOptions,
    @IKeybindingService keybindingService: IKeybindingService,
    @IContextMenuService contextMenuService: IContextMenuService,
    @IConfigurationService configurationService: IConfigurationService,
    @IContextKeyService contextKeyService: IContextKeyService,
    @IViewDescriptorService viewDescriptorService: IViewDescriptorService,
    @IInstantiationService protected override readonly instantiationService: IInstantiationService,
    @IOpenerService openerService: IOpenerService,
    @IThemeService themeService: IThemeService,
    @ITelemetryService telemetryService: ITelemetryService,
    @IHoverService hoverService: IHoverService,
  ) {
    super(options, keybindingService, contextMenuService, configurationService, contextKeyService, viewDescriptorService, instantiationService, openerService, themeService, telemetryService, hoverService);
  }

  protected override renderBody(container: HTMLElement): void {
    super.renderBody(container);

    // Mount React
    this.instantiationService.invokeFunction(accessor => {
      const disposables = mountPearAI(container, accessor);
      disposables?.forEach((d: IDisposable) => this._register(d));
    });
  }
}
