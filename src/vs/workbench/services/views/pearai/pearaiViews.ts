import { ViewContainer, ViewContainerLocation } from 'vs/workbench/common/views';

import { IExtensionService } from '../../extensions/common/extensions.js';
import { ITelemetryService } from '../../../../platform/telemetry/common/telemetry.js';
import { IViewDescriptorService } from '../../../common/views.js';
import { IInstantiationService } from '../../../../platform/instantiation/common/instantiation.js';
import { IContextKeyService } from '../../../../platform/contextkey/common/contextkey.js';
import { IStorageService } from '../../../../platform/storage/common/storage.js';
import { ILoggerService } from '../../../../platform/log/common/log.js';
import { ViewDescriptorService } from '../browser/viewDescriptorService.js';


const auxiliaryBarAllowedViewContainerIDs = ['workbench.view.extension.PearAI'];

export class CustomViewDescriptorService extends ViewDescriptorService implements IViewDescriptorService {
	constructor(
        @IInstantiationService instantiationService: IInstantiationService,
        @IContextKeyService contextKeyService: IContextKeyService,
        @IStorageService storageService: IStorageService,
        @IExtensionService extensionService: IExtensionService,
        @ITelemetryService telemetryService: ITelemetryService,
        @ILoggerService loggerService: ILoggerService,
    ) {
        super(instantiationService, contextKeyService, storageService, extensionService, telemetryService, loggerService);
	}


  override moveViewContainerToLocation(
    viewContainer: ViewContainer,
    location: ViewContainerLocation,
  ): void {
    if (
      location === ViewContainerLocation.AuxiliaryBar &&
      !auxiliaryBarAllowedViewContainerIDs.includes(viewContainer.id)
    ) {
      // Prevent the move since the ViewContainer ID is not in the allowed list
      return;
    }

    // Call the original method to proceed with the move
    super.moveViewContainerToLocation(viewContainer, location);
  }
}
