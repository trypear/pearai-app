import { ServicesAccessor } from '../../../../../../editor/browser/editorExtensions';
import { createRoot } from 'react-dom/client';
import * as React from 'react';
import App from './App';

export const mountPearAI = (
  container: HTMLElement,
  accessor: ServicesAccessor,
  props?: any
) => {
  const root = createRoot(container);
  root.render(<App {...props} />);

  // Return any cleanup disposables if needed
  return [];
};
