import { Registry } from 'vs/platform/registry/common/platform';
import { IWorkbenchContribution, IWorkbenchContributionsRegistry, Extensions as WorkbenchExtensions } from 'vs/workbench/common/contributions';
import { LifecyclePhase } from 'vs/workbench/services/lifecycle/common/lifecycle';
import { PearAuthenticationProvider, PEAR_AUTH_PROVIDER_ID } from './pearAuthenticationProvider';
import { registerPearAuthenticationCommands } from './pearAuthenticationCommands';
import { IAuthenticationService } from 'vs/workbench/services/authentication/common/authentication';
import { IStorageService } from 'vs/platform/storage/common/storage';
import { ILogService } from 'vs/platform/log/common/log';
import { IEnvironmentService } from 'vs/platform/environment/common/environment';
import { IProductService } from 'vs/platform/product/common/productService';
import { IInstantiationService } from 'vs/platform/instantiation/common/instantiation';
import { IDisposable, Disposable } from 'vs/base/common/lifecycle';
import { PearAuthenticationViewItem } from './pearAuthenticationViewItem';
import './pearAuthenticationUriHandler';

class PearAuthenticationContribution implements IWorkbenchContribution {
	private readonly _disposables = new Set<IDisposable>();

	constructor(
		@IAuthenticationService private readonly authenticationService: IAuthenticationService,
		@IStorageService private readonly storageService: IStorageService,
		@ILogService private readonly logService: ILogService,
		@IEnvironmentService private readonly environmentService: IEnvironmentService,
		@IProductService private readonly productService: IProductService,
		@IInstantiationService private readonly instantiationService: IInstantiationService
	) {
		this.registerAuthenticationProvider();
		registerPearAuthenticationCommands();
		this.registerViewItem();
	}

	private registerAuthenticationProvider(): void {
		const provider = new PearAuthenticationProvider(
			this.storageService,
			this.logService,
			this.environmentService,
			this.productService
		);

		this.authenticationService.registerAuthenticationProvider(
			PEAR_AUTH_PROVIDER_ID,
			provider
		);
	}

	private registerViewItem(): void {
		this._disposables.add(this.instantiationService.createInstance(PearAuthenticationViewItem));
	}

	dispose(): void {
		this._disposables.forEach(d => d.dispose());
		this._disposables.clear();
	}
}

Registry.as<IWorkbenchContributionsRegistry>(WorkbenchExtensions.Workbench)
	.registerWorkbenchContribution(
		PearAuthenticationContribution,
		LifecyclePhase.Restored
	);
