import { createContext, useContext } from 'react'
import type { IInstantiationService } from '../../../../../../../platform/instantiation/common/instantiation'

const VSCodeContext = createContext<IInstantiationService | null>(null)

export const useVSCodeService = <T>(serviceId: any): T => {
  const instantiationService = useContext(VSCodeContext)
  if (!instantiationService) {
    throw new Error('VSCode services not available')
  }
  return instantiationService.invokeFunction((accessor: any) => accessor.get(serviceId))
}
