import React, { useState, useEffect } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import axios from 'axios';

interface HistoryItem {
  scan_id: number;
  scan_date: string;
  dr_grade: number | null;
  glaucoma_detected: boolean;
  overall_severity: string;
}

export const PatientDashboardPage: React.FC = () => {
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [patientId] = useState(localStorage.getItem('patient_id') || '1');

  useEffect(() => {
    const fetchHistory = async () => {
      try {
        const response = await axios.get(
          `${process.env.REACT_APP_API_URL}/api/patients/${patientId}/history`,
          {
            headers: {
              'Authorization': `Bearer ${localStorage.getItem('access_token')}`,
            },
          }
        );
        setHistory(response.data);
      } catch (error) {
        console.error('Failed to load history');
      } finally {
        setLoading(false);
      }
    };

    fetchHistory();
  }, [patientId]);

  // Prepare data for chart
  const chartData = history.map((item) => ({
    date: new Date(item.scan_date).toLocaleDateString(),
    dr_grade: item.dr_grade ?? 0,
    timestamp: item.scan_date,
  }));

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-800 mb-2">Your Health Dashboard</h1>
          <p className="text-gray-600">Track your retinal screening results over time</p>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-lg shadow p-6">
            <p className="text-gray-600 text-sm mb-2">Total Scans</p>
            <p className="text-3xl font-bold text-blue-600">{history.length}</p>
          </div>
          <div className="bg-white rounded-lg shadow p-6">
            <p className="text-gray-600 text-sm mb-2">Last Scan</p>
            <p className="text-lg font-semibold text-gray-800">
              {history.length > 0 ? new Date(history[history.length - 1].scan_date).toLocaleDateString() : 'Never'}
            </p>
          </div>
          <div className="bg-white rounded-lg shadow p-6">
            <p className="text-gray-600 text-sm mb-2">Current Status</p>
            <p className="text-lg font-semibold text-green-600">
              {history.length > 0 ? history[history.length - 1].overall_severity : 'N/A'}
            </p>
          </div>
          <div className="bg-white rounded-lg shadow p-6">
            <p className="text-gray-600 text-sm mb-2">Glaucoma Risk</p>
            <p className="text-lg font-semibold text-gray-800">
              {history.length > 0 ? (history[history.length - 1].glaucoma_detected ? 'High' : 'Low') : 'N/A'}
            </p>
          </div>
        </div>

        {/* Trend Chart */}
        {chartData.length > 0 && (
          <div className="bg-white rounded-lg shadow p-6 mb-8">
            <h2 className="text-xl font-semibold text-gray-800 mb-6">Diabetic Retinopathy Grade Trend</h2>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis domain={[0, 4]} />
                <Tooltip />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="dr_grade"
                  stroke="#3b82f6"
                  name="DR Grade"
                  dot={{ fill: '#3b82f6' }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}

        {/* Screening History */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-gray-800 mb-6">Screening History</h2>
          {loading ? (
            <p className="text-gray-600">Loading...</p>
          ) : history.length === 0 ? (
            <p className="text-gray-600">No screening history yet. Upload your first scan to get started.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-100">
                  <tr>
                    <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Date</th>
                    <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">DR Grade</th>
                    <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Glaucoma</th>
                    <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Severity</th>
                    <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Action</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((item, index) => (
                    <tr key={index} className="border-b hover:bg-gray-50">
                      <td className="px-6 py-4 text-sm text-gray-800">
                        {new Date(item.scan_date).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-800">
                        {item.dr_grade !== null ? `Grade ${item.dr_grade}` : 'N/A'}
                      </td>
                      <td className="px-6 py-4 text-sm">
                        <span className={item.glaucoma_detected ? 'text-red-600 font-semibold' : 'text-green-600'}>
                          {item.glaucoma_detected ? 'Detected' : 'Not Detected'}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm capitalize text-gray-800">
                        {item.overall_severity}
                      </td>
                      <td className="px-6 py-4 text-sm">
                        <a href={`/report/${item.scan_id}`} className="text-blue-600 hover:underline">
                          View Report
                        </a>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default PatientDashboardPage;
