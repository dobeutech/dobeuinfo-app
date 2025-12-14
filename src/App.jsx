import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import HomePage from './pages/HomePage'
import SubmissionPage from './pages/SubmissionPage'

function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/submit" element={<SubmissionPage />} />
      </Routes>
    </Layout>
  )
}

export default App

