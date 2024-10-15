import InventoryPage from "./pages/InventoryPage";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export default function App() {
	return (
		<div className="h-full">
			<Tabs defaultValue="inventory">
				<TabsList>
					<TabsTrigger value="inventory">Inventory</TabsTrigger>
					<TabsTrigger value="perplexity">Perplexity</TabsTrigger>
				</TabsList>
				<TabsContent value="inventory">
					<InventoryPage />
				</TabsContent>
				<TabsContent value="perplexity">Perplexity here.</TabsContent>
			</Tabs>
		</div>
	);
}
