import { Registry } from '../../../../platform/registry/common/platform';
import { Extensions as ViewExtensions, IViewsRegistry, ViewContainer, ViewContainerLocation, IViewContainersRegistry, IViewPaneContainer } from 'vs/workbench/common/views';
import { PearAIPane } from './pearAIPane';
import { localize2 } from '../../../../nls';
import { SyncDescriptor } from '../../../../platform/instantiation/common/descriptors';
import { ViewPaneContainer } from '../../../../workbench/browser/parts/views/viewPaneContainer';

// Register view container
const viewContainer = Registry.as<IViewContainersRegistry>(ViewExtensions.ViewContainersRegistry).registerViewContainer(
	{
		id: 'pearai',
		title: localize2('pearai', "PearAI"),
		ctorDescriptor: new SyncDescriptor<IViewPaneContainer>(ViewPaneContainer),
		storageId: 'pearai',
		order: 6,
	}, ViewContainerLocation.Sidebar
);

// Register view
Registry.as<IViewsRegistry>(ViewExtensions.ViewsRegistry).registerViews([{
	id: PearAIPane.ID,
	name: localize2('pearai.view', "PearAI"),
	canToggleVisibility: true,
	canMoveView: true,
	ctorDescriptor: new SyncDescriptor(PearAIPane),
}], viewContainer);
