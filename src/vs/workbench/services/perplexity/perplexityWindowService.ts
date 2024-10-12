import { registerSingleton } from "vs/platform/instantiation/common/extensions";
import {
	IPerplexityWindowService,
	PerplexityWindowService,
} from "./IPerplexityWindowService";
import { InstantiationType } from "vs/platform/instantiation/common/instantiation";

registerSingleton(
	IPerplexityWindowService,
	PerplexityWindowService,
	InstantiationType.Delayed,
);
