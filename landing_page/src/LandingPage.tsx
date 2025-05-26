import React, { useState, useEffect } from 'react';
import { ChevronRight, Clock, Users, Zap, Check, ExternalLink, Star, Book, Code, Cpu, ArrowRight, Menu, X, Activity, AlertCircle, BarChart3, Cloud, Terminal } from 'lucide-react';

const LandingPage = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const modules = [
    { id: 1, title: "Introduction to Observability", duration: "30 min", level: "Essential" },
    { id: 2, title: "Beginning Your Observability Journey", duration: "45 min", level: "Essential" },
    { id: 3, title: "Building Dashboards and Alerts", duration: "60 min", level: "Standard" },
    { id: 4, title: "Advanced Application Insights", duration: "90 min", level: "Standard" },
    { id: 5, title: "Multi-Cloud Integration", duration: "120 min", level: "Advanced" },
    { id: 6, title: "AI-Enhanced Monitoring", duration: "90 min", level: "Advanced" },
    { id: 7, title: "Enterprise Implementation", duration: "120 min", level: "Advanced" },
    { id: 8, title: "Hands-On Challenge Labs", duration: "180 min", level: "Advanced" }
  ];

  const benefits = [
    { metric: "MTTR", description: "From hours to minutes", icon: Clock },
    { metric: "80%", description: "Reduction in false positives", icon: AlertCircle },
    { metric: "70%", description: "Proactive improvements", icon: Activity },
    { metric: "60%", description: "Less reactive firefighting", icon: Zap }
  ];

  const maturityStages = [
    { stage: "Reactive", description: "Basic monitoring and alerting", icon: "🔍" },
    { stage: "Proactive", description: "Trend analysis and planning", icon: "📊" },
    { stage: "Predictive", description: "Anomaly detection", icon: "🔮" },
    { stage: "Autonomous", description: "Self-healing systems", icon: "🤖" }
  ];

  const prerequisites = [
    "Azure Free Account",
    "GitHub account with Copilot",
    "Azure SRE Agent preview access",
    "VS Code installed",
    "Azure CLI installed",
    "Basic cloud knowledge"
  ];

  const keyFeatures = [
    {
      title: "Complete Automation",
      description: "One-command deployment with quick-start.sh",
      icon: "🤖"
    },
    {
      title: "Infrastructure as Code",
      description: "Production-ready Terraform configurations",
      icon: "🏗️"
    },
    {
      title: "Ready Applications",
      description: "Sample apps with full telemetry",
      icon: "🚀"
    },
    {
      title: "Pre-Built Dashboards",
      description: "Grafana dashboards auto-deployed",
      icon: "📊"
    }
  ];

  const relatedRepos = [
    {
      title: "Design-to-Code",
      description: "Transform Figma designs into production-ready code with AI assistance",
      link: "https://github.com/paulasilvatech/Design-to-Code-Dev"
    },
    {
      title: "AI Code Development",
      description: "Leverage AI tools to optimize and improve code quality in enterprise environments",
      link: "https://github.com/paulasilvatech/Code-AI-Dev"
    },
    {
      title: "Agentic Operations",
      description: "Implement comprehensive observability solutions for cloud applications",
      link: "https://github.com/paulasilvatech/Agentic-Ops-Dev"
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-orange-900 to-red-900 text-white">
      {/* Navigation */}
      <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${scrolled ? 'bg-gray-900/95 backdrop-blur-md shadow-lg' : 'bg-transparent'}`}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-2">
              <Activity className="w-8 h-8 text-orange-400" />
              <span className="text-xl font-bold">Agentic Operations</span>
            </div>
            
            <div className="hidden md:flex items-center space-x-8">
              <a href="#modules" className="hover:text-orange-400 transition-colors">Modules</a>
              <a href="#impact" className="hover:text-orange-400 transition-colors">Impact</a>
              <a href="#stages" className="hover:text-orange-400 transition-colors">Maturity Stages</a>
              <a href="#start" className="hover:text-orange-400 transition-colors">Get Started</a>
              <a href="https://github.com/paulasilvatech/Agentic-Ops-Dev" target="_blank" rel="noopener noreferrer" className="flex items-center space-x-1 bg-orange-600 hover:bg-orange-700 px-4 py-2 rounded-lg transition-colors">
                <Star className="w-4 h-4" />
                <span>Star on GitHub</span>
              </a>
            </div>

            <button onClick={() => setIsMenuOpen(!isMenuOpen)} className="md:hidden">
              {isMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {/* Mobile menu */}
        {isMenuOpen && (
          <div className="md:hidden bg-gray-900/95 backdrop-blur-md">
            <div className="px-4 pt-2 pb-3 space-y-1">
              <a href="#modules" className="block px-3 py-2 hover:bg-gray-800 rounded-md">Modules</a>
              <a href="#impact" className="block px-3 py-2 hover:bg-gray-800 rounded-md">Impact</a>
              <a href="#stages" className="block px-3 py-2 hover:bg-gray-800 rounded-md">Maturity Stages</a>
              <a href="#start" className="block px-3 py-2 hover:bg-gray-800 rounded-md">Get Started</a>
            </div>
          </div>
        )}
      </nav>

      {/* Hero Section */}
      <section className="relative min-h-screen flex items-center justify-center px-4 pt-16">
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute -inset-[10px] opacity-50">
            <div className="absolute top-0 -left-4 w-72 h-72 bg-orange-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob"></div>
            <div className="absolute top-0 -right-4 w-72 h-72 bg-amber-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-2000"></div>
            <div className="absolute -bottom-8 left-20 w-72 h-72 bg-red-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-4000"></div>
          </div>
        </div>

        <div className="relative max-w-4xl mx-auto text-center">
          <div className="flex justify-center mb-6">
            <span className="bg-orange-600/20 text-orange-300 px-4 py-2 rounded-full text-sm font-medium backdrop-blur-sm">
              🚀 AI-Enhanced Observability Workshop
            </span>
          </div>
          
          <h1 className="text-5xl md:text-7xl font-bold mb-6 bg-clip-text text-transparent bg-gradient-to-r from-orange-400 to-red-400">
            Agentic Operations & Observability
          </h1>
          
          <p className="text-xl md:text-2xl text-gray-300 mb-8 max-w-3xl mx-auto">
            Master comprehensive observability for cloud applications using Azure Monitor, Application Insights, and AI-powered tools like Azure SRE Agent.
          </p>
          
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <a href="https://agentic-ops.dev" target="_blank" rel="noopener noreferrer" className="group bg-gradient-to-r from-orange-600 to-red-600 hover:from-orange-700 hover:to-red-700 text-white px-8 py-4 rounded-lg font-semibold flex items-center justify-center space-x-2 transition-all transform hover:scale-105">
              <span>Visit Workshop Website</span>
              <ExternalLink className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </a>
            <a href="#start" className="bg-gray-800 hover:bg-gray-700 text-white px-8 py-4 rounded-lg font-semibold flex items-center justify-center space-x-2 transition-all">
              <span>Quick Start</span>
              <ChevronRight className="w-5 h-5" />
            </a>
          </div>

          <div className="mt-12 flex flex-wrap justify-center gap-8 text-sm text-gray-400">
            <div className="flex items-center space-x-2">
              <Clock className="w-5 h-5" />
              <span>2 - 8+ hours</span>
            </div>
            <div className="flex items-center space-x-2">
              <Users className="w-5 h-5" />
              <span>Essential to Advanced</span>
            </div>
            <div className="flex items-center space-x-2">
              <Zap className="w-5 h-5" />
              <span>Hands-on Learning</span>
            </div>
          </div>
        </div>
      </section>

      {/* The Challenge Section */}
      <section className="py-20 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="bg-gradient-to-br from-orange-600/20 to-red-600/20 rounded-2xl p-8 md:p-12 backdrop-blur-sm">
            <h3 className="text-2xl md:text-3xl font-bold mb-8 text-center">The Observability Challenge</h3>
            <div className="text-center mb-8">
              <p className="text-xl text-gray-300 italic">
                "Traditional monitoring only shows you what's wrong, not why or how to fix it"
              </p>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-8">
              <div className="flex items-start space-x-3">
                <AlertCircle className="w-6 h-6 text-orange-400 flex-shrink-0 mt-1" />
                <p className="text-gray-300">Monitoring only catches problems you anticipated</p>
              </div>
              <div className="flex items-start space-x-3">
                <AlertCircle className="w-6 h-6 text-orange-400 flex-shrink-0 mt-1" />
                <p className="text-gray-300">High alert fatigue leads to missed critical issues</p>
              </div>
              <div className="flex items-start space-x-3">
                <AlertCircle className="w-6 h-6 text-orange-400 flex-shrink-0 mt-1" />
                <p className="text-gray-300">Difficult to correlate issues across microservices</p>
              </div>
              <div className="flex items-start space-x-3">
                <AlertCircle className="w-6 h-6 text-orange-400 flex-shrink-0 mt-1" />
                <p className="text-gray-300">Reactive troubleshooting instead of proactive optimization</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Business Impact Section */}
      <section id="impact" className="py-20 px-4 bg-gray-900/50">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-4">Business Impact</h2>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto">
              Organizations implementing comprehensive observability achieve transformative results
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {benefits.map((benefit, index) => (
              <div key={index} className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-8 text-center transform hover:scale-105 transition-all">
                <benefit.icon className="w-12 h-12 mx-auto mb-4 text-orange-400" />
                <div className="text-5xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-orange-400 to-red-400 mb-2">
                  {benefit.metric}
                </div>
                <p className="text-gray-300">{benefit.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Maturity Stages Section */}
      <section id="stages" className="py-20 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-4">Observability Maturity Journey</h2>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto">
              Progress through four stages of observability maturity
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {maturityStages.map((stage, index) => (
              <div key={index} className="relative">
                <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-6 hover:bg-gray-800/70 transition-all">
                  <div className="text-4xl mb-4">{stage.icon}</div>
                  <h3 className="text-xl font-semibold mb-2 text-orange-400">{stage.stage}</h3>
                  <p className="text-gray-300 text-sm">{stage.description}</p>
                </div>
                {index < maturityStages.length - 1 && (
                  <div className="hidden lg:block absolute top-1/2 -right-3 transform -translate-y-1/2">
                    <ArrowRight className="w-6 h-6 text-orange-400" />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Modules Section */}
      <section id="modules" className="py-20 px-4 bg-gray-900/50">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-4">Workshop Modules</h2>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto">
              Comprehensive learning path from traditional monitoring to AI-enhanced observability
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {modules.map((module) => (
              <div key={module.id} className="group bg-gray-800/50 backdrop-blur-sm rounded-xl p-6 hover:bg-gray-800/70 transition-all hover:transform hover:scale-105">
                <div className="flex items-start justify-between mb-4">
                  <span className="text-3xl font-bold text-gray-600">0{module.id}</span>
                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                    module.level === 'Essential' ? 'bg-green-600/20 text-green-300' :
                    module.level === 'Standard' ? 'bg-yellow-600/20 text-yellow-300' :
                    'bg-red-600/20 text-red-300'
                  }`}>
                    {module.level}
                  </span>
                </div>
                <h3 className="text-xl font-semibold mb-2 group-hover:text-orange-400 transition-colors">
                  {module.title}
                </h3>
                <div className="flex items-center text-gray-400 text-sm">
                  <Clock className="w-4 h-4 mr-1" />
                  <span>{module.duration}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Key Features Section */}
      <section className="py-20 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-4">Key Features</h2>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto">
              Everything you need for production-ready observability
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {keyFeatures.map((feature, index) => (
              <div key={index} className="bg-gradient-to-br from-orange-600/10 to-red-600/10 rounded-xl p-8 backdrop-blur-sm hover:from-orange-600/20 hover:to-red-600/20 transition-all">
                <div className="flex items-start space-x-4">
                  <span className="text-4xl">{feature.icon}</span>
                  <div>
                    <h3 className="text-xl font-semibold mb-2">{feature.title}</h3>
                    <p className="text-gray-300">{feature.description}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Prerequisites Section */}
      <section id="prerequisites" className="py-20 px-4 bg-gray-900/50">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div>
              <h2 className="text-4xl md:text-5xl font-bold mb-6">Prerequisites</h2>
              <p className="text-xl text-gray-300 mb-8">
                Essential tools and knowledge for your observability journey. All tools have free tiers available.
              </p>
              <ul className="space-y-4">
                {prerequisites.map((prereq, index) => (
                  <li key={index} className="flex items-center space-x-3">
                    <Check className="w-5 h-5 text-green-400 flex-shrink-0" />
                    <span className="text-lg">{prereq}</span>
                  </li>
                ))}
              </ul>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-gradient-to-br from-orange-600/20 to-red-600/20 rounded-xl p-6 backdrop-blur-sm">
                <BarChart3 className="w-12 h-12 text-orange-400 mb-3" />
                <h3 className="text-lg font-semibold mb-2">Three Pillars</h3>
                <p className="text-gray-300 text-sm">Master metrics, logs, and traces</p>
              </div>
              <div className="bg-gradient-to-br from-red-600/20 to-orange-600/20 rounded-xl p-6 backdrop-blur-sm">
                <Cloud className="w-12 h-12 text-red-400 mb-3" />
                <h3 className="text-lg font-semibold mb-2">Multi-Cloud</h3>
                <p className="text-gray-300 text-sm">Monitor Azure, AWS, and GCP</p>
              </div>
              <div className="bg-gradient-to-br from-amber-600/20 to-orange-600/20 rounded-xl p-6 backdrop-blur-sm">
                <Cpu className="w-12 h-12 text-amber-400 mb-3" />
                <h3 className="text-lg font-semibold mb-2">AI-Enhanced</h3>
                <p className="text-gray-300 text-sm">Azure SRE Agent integration</p>
              </div>
              <div className="bg-gradient-to-br from-orange-600/20 to-amber-600/20 rounded-xl p-6 backdrop-blur-sm">
                <Terminal className="w-12 h-12 text-orange-400 mb-3" />
                <h3 className="text-lg font-semibold mb-2">Automation</h3>
                <p className="text-gray-300 text-sm">One-command deployment</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Getting Started Section */}
      <section id="start" className="py-20 px-4">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">Quick Start in Minutes</h2>
          <p className="text-xl text-gray-300 mb-12">
            Deploy a complete observability environment with one command
          </p>

          <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-8 mb-12">
            <h3 className="text-2xl font-semibold mb-6 text-orange-400">🚀 Automated Deployment</h3>
            <div className="text-left space-y-4">
              <div className="bg-gray-900 rounded-lg p-4 overflow-x-auto">
                <code className="text-sm">
                  <span className="text-gray-500"># 1. Fork and Clone this Repository</span><br />
                  <span className="text-orange-400">git clone</span> https://github.com/YourUsername/Agentic-Ops-Dev.git<br />
                  <span className="text-orange-400">cd</span> Agentic-Ops-Dev<br /><br />
                  
                  <span className="text-gray-500"># 2. Deploy Everything Automatically (10-15 minutes)</span><br />
                  <span className="text-orange-400">cd</span> resources<br />
                  <span className="text-orange-400">./quick-start.sh</span> deploy YOUR_AZURE_SUBSCRIPTION_ID<br /><br />
                  
                  <span className="text-gray-500"># 3. Start Learning with Full Environment</span><br />
                  <span className="text-orange-400">./quick-start.sh</span> start
                </code>
              </div>
            </div>
          </div>

          <div className="space-y-6 text-left">
            <h3 className="text-2xl font-semibold text-center mb-6">📚 Manual Learning Path</h3>
            
            <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-6">
              <div className="flex items-start space-x-4">
                <span className="bg-orange-600 text-white w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 font-semibold">1</span>
                <div className="flex-1">
                  <h3 className="text-xl font-semibold mb-2">Register for Workshop Access</h3>
                  <p className="text-gray-300">Visit agentic-ops.dev and complete Azure SRE Agent preview registration</p>
                </div>
              </div>
            </div>

            <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-6">
              <div className="flex items-start space-x-4">
                <span className="bg-orange-600 text-white w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 font-semibold">2</span>
                <div className="flex-1">
                  <h3 className="text-xl font-semibold mb-2">Follow the Workshop Structure</h3>
                  <p className="text-gray-300">Start with Introduction to Observability and progress through modules</p>
                </div>
              </div>
            </div>

            <div className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-6">
              <div className="flex items-start space-x-4">
                <span className="bg-orange-600 text-white w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 font-semibold">3</span>
                <div className="flex-1">
                  <h3 className="text-xl font-semibold mb-2">Leverage Automation Resources</h3>
                  <p className="text-gray-300">Use scripts, templates, and pre-built applications in /resources/</p>
                </div>
              </div>
            </div>
          </div>

          <div className="mt-12">
            <a href="https://github.com/paulasilvatech/Agentic-Ops-Dev" target="_blank" rel="noopener noreferrer" className="inline-flex items-center space-x-2 bg-gradient-to-r from-orange-600 to-red-600 hover:from-orange-700 hover:to-red-700 text-white px-8 py-4 rounded-lg font-semibold transition-all transform hover:scale-105">
              <span>View on GitHub</span>
              <ExternalLink className="w-5 h-5" />
            </a>
          </div>
        </div>
      </section>

      {/* Related Repositories */}
      <section className="py-20 px-4 bg-gray-900/50">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-4">Related Resources</h2>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto">
              Explore our comprehensive ecosystem of AI-powered development workshops
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {relatedRepos.map((repo, index) => (
              <a key={index} href={repo.link} target="_blank" rel="noopener noreferrer" className="group bg-gray-800/50 backdrop-blur-sm rounded-xl p-6 hover:bg-gray-800/70 transition-all hover:transform hover:scale-105">
                <div className="flex items-start justify-between mb-4">
                  <Book className="w-8 h-8 text-orange-400" />
                  <ExternalLink className="w-5 h-5 text-gray-400 group-hover:text-orange-400 transition-colors" />
                </div>
                <h3 className="text-xl font-semibold mb-2 group-hover:text-orange-400 transition-colors">
                  {repo.title}
                </h3>
                <p className="text-gray-300">
                  {repo.description}
                </p>
              </a>
            ))}
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-4 border-t border-gray-800">
        <div className="max-w-7xl mx-auto text-center">
          <p className="text-gray-400 mb-4">
            Developed by{' '}
            <a href="https://github.com/paulasilvatech" target="_blank" rel="noopener noreferrer" className="text-orange-400 hover:text-orange-300">
              Paula Silva
            </a>
            , Developer Productivity Global Black Belt at Microsoft Americas
          </p>
          <p className="text-gray-500">
            Providing a comprehensive approach to implementing AI-enhanced observability solutions for modern cloud applications
          </p>
        </div>
      </footer>
    </div>
  );
};

export default LandingPage;