/*--------------------------------------------------------------------------------------
 *  Copyright 2025 Glass Devtools, Inc. All rights reserved.
 *  Licensed under the Apache License, Version 2.0. See LICENSE.txt for more information.
 *--------------------------------------------------------------------------------------*/

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { FeatureName, featureNames, ModelSelection, modelSelectionsEqual, ProviderName, providerNames } from '../../../../../../../platform/pearai/common/pearaiSettingsTypes.js';
import { useSettingsState, useRefreshModelState, useAccessor } from '../util/services.js';
import { _VoidSelectBox, VoidCustomSelectBox } from '../util/inputs.js';
import { SelectBox } from '../../../../../../../base/browser/ui/selectBox/selectBox.js';
import { VOID_OPEN_SETTINGS_ACTION_ID, VOID_TOGGLE_SETTINGS_ACTION_ID } from '../../../pearaiSettingsPane.js';
import { ModelOption } from '../../../../../../../platform/pearai/common/pearaiSettingsService.js';



const optionsEqual = (m1: ModelOption[], m2: ModelOption[]) => {
  if (m1.length !== m2.length) return false;
  for (let i = 0; i < m1.length; i++) {
    if (!modelSelectionsEqual(m1[i].selection, m2[i].selection)) return false;
  }
  return true;
};

const ModelSelectBox = ({ options, featureName }: {options: ModelOption[];featureName: FeatureName;}) => {
  const accessor = useAccessor();
  const voidSettingsService = accessor.get('IVoidSettingsService');

  const selection = voidSettingsService.state.modelSelectionOfFeature[featureName];
  const selectedOption = selection ? voidSettingsService.state._modelOptions.find((v) => modelSelectionsEqual(v.selection, selection)) : options[0];

  const onChangeOption = useCallback((newOption: ModelOption) => {
    voidSettingsService.setModelSelectionOfFeature(featureName, newOption.selection);
  }, [voidSettingsService, featureName]);

  return <VoidCustomSelectBox
    options={options}
    selectedOption={selectedOption}
    onChangeOption={onChangeOption}
    getOptionDisplayName={(option) => option.selection.modelName}
    getOptionDropdownName={(option) => option.name}
    getOptionsEqual={(a, b) => optionsEqual([a], [b])}
    className={`void-text-xs void-text-void-fg-3 void-px-1`}
    matchInputWidth={false}
    isMenuPositionFixed={featureName === 'Ctrl+K' ? false : true} />;

};
// const ModelSelectBox = ({ options, featureName }: { options: ModelOption[], featureName: FeatureName }) => {
// 	const accessor = useAccessor()

// 	const voidSettingsService = accessor.get('IVoidSettingsService')

// 	let weChangedText = false

// 	return <VoidSelectBox
// 		className='@@[&_select]:!void-text-xs text-void-fg-3'
// 		options={options}
// 		onChangeSelection={useCallback((newVal: ModelSelection) => {
// 			if (weChangedText) return
// 			voidSettingsService.setModelSelectionOfFeature(featureName, newVal)
// 		}, [voidSettingsService, featureName])}
// 		// we are responsible for setting the initial state here. always sync instance when state changes.
// 		onCreateInstance={useCallback((instance: SelectBox) => {
// 			const syncInstance = () => {
// 				const modelsListRef = voidSettingsService.state._modelOptions // as a ref
// 				const settingsAtProvider = voidSettingsService.state.modelSelectionOfFeature[featureName]
// 				const selectionIdx = settingsAtProvider === null ? -1 : modelsListRef.findIndex(v => modelSelectionsEqual(v.value, settingsAtProvider))
// 				weChangedText = true
// 				instance.select(selectionIdx === -1 ? 0 : selectionIdx)
// 				weChangedText = false
// 			}
// 			syncInstance()
// 			const disposable = voidSettingsService.onDidChangeState(syncInstance)
// 			return [disposable]
// 		}, [voidSettingsService, featureName])}
// 	/>
// }

const MemoizedModelSelectBox = ({ featureName }: {featureName: FeatureName;}) => {
  const settingsState = useSettingsState();
  const oldOptionsRef = useRef<ModelOption[]>([]);
  const [memoizedOptions, setMemoizedOptions] = useState(oldOptionsRef.current);
  useEffect(() => {
    const oldOptions = oldOptionsRef.current;
    const newOptions = settingsState._modelOptions;
    if (!optionsEqual(oldOptions, newOptions)) {
      setMemoizedOptions(newOptions);
    }
    oldOptionsRef.current = newOptions;
  }, [settingsState._modelOptions]);

  return <ModelSelectBox featureName={featureName} options={memoizedOptions} />;

};

export const WarningBox = ({ text, onClick, className }: {text: string;onClick?: () => void;className?: string;}) => {

  return <div
    className={` void-text-void-warning void-brightness-90 void-opacity-90 void-text-xs void-text-ellipsis ${


    onClick ? `hover:void-brightness-75 void-transition-all void-duration-200 void-cursor-pointer` : ""} void-flex void-items-center void-flex-nowrap ${

    className} `}

    onClick={onClick}>


		<span>{text}</span>
	</div>;
  // return <VoidSelectBox
  // 	options={[{ text: 'Please add a model!', value: null }]}
  // 	onChangeSelection={() => { }}
  // />
};

export const ModelDropdown = ({ featureName }: {featureName: FeatureName;}) => {
  const settingsState = useSettingsState();

  const accessor = useAccessor();
  const commandService = accessor.get('ICommandService');

  const openSettings = () => {commandService.executeCommand(VOID_OPEN_SETTINGS_ACTION_ID);};

  return <>
		{settingsState._modelOptions.length === 0 ?
    <WarningBox onClick={openSettings} text='Provider required' /> :
    <MemoizedModelSelectBox featureName={featureName} />
    }
	</>;
};