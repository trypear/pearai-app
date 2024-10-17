import  { useState, useEffect } from 'react'
import { Search } from 'lucide-react'
import { Input } from "@/components/ui/input"
import { Switch } from "@/components/ui/switch"
import { Button } from "@/components/ui/button"
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"

interface AITool {
  id: string
  name: string
  description: string
  enabled: boolean
}

const initialTools: AITool[] = [
  { id: '1', name: 'Perplexity', description: 'AI-powered search engine for complex queries', enabled: true },
  { id: '2', name: 'Continue', description: 'AI pair programmer for seamless coding assistance', enabled: true },
  { id: '3', name: 'mem0', description: 'AI-enhanced note-taking and knowledge management', enabled: false },
  { id: '4', name: 'aider', description: 'AI-powered coding assistant for various tasks', enabled: true },
]

export default function AIToolInventory() {
  const [tools, setTools] = useState<AITool[]>(initialTools)
  const [searchQuery, setSearchQuery] = useState('')
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    // Simulating an API call to fetch tools
    const fetchTools = async () => {
      try {
        await new Promise(resolve => setTimeout(resolve, 1000)) // Simulated delay
        setTools(initialTools)
        setIsLoading(false)
      } catch (err) {
        setError('Failed to load AI tools. Please try again.')
        setIsLoading(false)
      }
    }

    fetchTools()
  }, [])

  const handleToggle = (id: string) => {
    setTools(tools.map(tool => 
      tool.id === id ? { ...tool, enabled: !tool.enabled } : tool
    ))
  }

  const filteredTools = tools.filter(tool => 
    tool.name.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const handleSave = () => {
    // Simulating saving the settings
    console.log('Saving settings:', tools)
    // Here you would typically send the updated tools to your backend or VSCode extension
  }

  if (isLoading) {
    return <div className="flex justify-center items-center h-full">Loading...</div>
  }

  if (error) {
    return <div className="flex justify-center items-center h-full text-red-500">{error}</div>
  }

  return (
    <div className="flex flex-col h-full bg-background text-foreground p-6 overflow-hidden">
      <header className="mb-6">
        <h1 className="text-2xl font-bold mb-2">PearAI Inventory</h1>
        <div className="relative">
          <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" />
          <Input
            type="text"
            placeholder="Search AI tools..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 w-full"
            aria-label="Search AI tools"
          />
        </div>
      </header>

      <main className="flex-grow overflow-auto">
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {filteredTools.map(tool => (
            <Card key={tool.id}>
              <CardHeader>
                <CardTitle className="flex justify-between items-center">
                  <span>{tool.name}</span>
                  <Switch
                    checked={tool.enabled}
                    onCheckedChange={() => handleToggle(tool.id)}
                    aria-label={`Toggle ${tool.name}`}
                  />
                </CardTitle>
                <CardDescription>{tool.description}</CardDescription>
              </CardHeader>
            </Card>
          ))}
        </div>
      </main>

      <footer className="mt-6">
        <Button onClick={handleSave} className="w-full">
          Save Settings
        </Button>
      </footer>
    </div>
  )
}