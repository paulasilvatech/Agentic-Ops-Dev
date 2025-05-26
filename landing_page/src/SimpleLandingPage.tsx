import { useState } from 'react';

const SimpleLandingPage = () => {
  const [count, setCount] = useState(0);

  return (
    <div style={{ 
      minHeight: '100vh', 
      background: 'linear-gradient(135deg, #1e293b, #ea580c, #dc2626)', 
      color: 'white',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '20px',
      fontFamily: 'system-ui, sans-serif'
    }}>
      <h1 style={{ fontSize: '3rem', marginBottom: '1rem', textAlign: 'center' }}>
        🤖 Agentic DevOps Workshop
      </h1>
      
      <p style={{ fontSize: '1.5rem', marginBottom: '2rem', textAlign: 'center', maxWidth: '600px' }}>
        Master Azure observability with AI-enhanced monitoring and automated incident response
      </p>

      <div style={{ 
        background: 'rgba(255,255,255,0.1)', 
        padding: '20px', 
        borderRadius: '10px',
        marginBottom: '2rem'
      }}>
        <h2>Test Counter: {count}</h2>
        <button 
          onClick={() => setCount(count + 1)}
          style={{
            background: '#ea580c',
            color: 'white',
            border: 'none',
            padding: '10px 20px',
            borderRadius: '5px',
            cursor: 'pointer',
            fontSize: '1rem'
          }}
        >
          Click me!
        </button>
      </div>

      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
        gap: '20px',
        maxWidth: '1000px',
        width: '100%'
      }}>
        <div style={{ 
          background: 'rgba(255,255,255,0.1)', 
          padding: '20px', 
          borderRadius: '10px',
          textAlign: 'center'
        }}>
          <h3>🔍 Observability</h3>
          <p>Monitor applications with Azure Application Insights</p>
        </div>
        
        <div style={{ 
          background: 'rgba(255,255,255,0.1)', 
          padding: '20px', 
          borderRadius: '10px',
          textAlign: 'center'
        }}>
          <h3>🤖 AI Enhancement</h3>
          <p>Leverage AI for predictive monitoring</p>
        </div>
        
        <div style={{ 
          background: 'rgba(255,255,255,0.1)', 
          padding: '20px', 
          borderRadius: '10px',
          textAlign: 'center'
        }}>
          <h3>🚀 Automation</h3>
          <p>Automated deployment and scaling</p>
        </div>
      </div>

      <footer style={{ marginTop: '3rem', textAlign: 'center', opacity: 0.7 }}>
        <p>© 2025 Agentic DevOps Workshop - Azure Observability</p>
      </footer>
    </div>
  );
};

export default SimpleLandingPage;
