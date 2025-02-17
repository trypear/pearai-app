import { ServicesAccessor } from '../../../../../../editor/browser/editorExtensions';
import { IDisposable } from '../../../../../../base/common/lifecycle';

export function mountPearAI(
  container: HTMLElement,
  accessor: ServicesAccessor,
  props?: any
): IDisposable[];
