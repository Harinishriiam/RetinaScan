import React, { useState } from 'react';
import { Upload, AlertCircle, CheckCircle } from 'lucide-react';
import axios from 'axios';

export const ScanUploadPage: React.FC = () => {
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadStatus, setUploadStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [message, setMessage] = useState('');

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0];
    if (selectedFile) {
      setFile(selectedFile);
      
      // Create preview
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreview(reader.result as string);
      };
      reader.readAsDataURL(selectedFile);
    }
  };

  const handleUpload = async () => {
    if (!file) return;

    setUploading(true);
    const formData = new FormData();
    formData.append('file', file);
    formData.append('patient_id', localStorage.getItem('patient_id') || '1');

    try {
      await axios.post(
        `${process.env.REACT_APP_API_URL}/api/scans/upload`,
        formData,
        {
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': `Bearer ${localStorage.getItem('access_token')}`,
          },
        }
      );
      setUploadStatus('success');
      setMessage('Image uploaded successfully! Analysis in progress...');
      setFile(null);
      setPreview(null);
    } catch (error: any) {
      setUploadStatus('error');
      setMessage(error.response?.data?.detail || 'Upload failed');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-800 mb-8">Upload Retinal Image</h1>

        <div className="bg-white rounded-lg shadow-lg p-8">
          {/* Upload Area */}
          <div className="border-2 border-dashed border-blue-300 rounded-lg p-12 text-center mb-8">
            <Upload className="w-12 h-12 text-blue-600 mx-auto mb-4" />
            <p className="text-gray-700 mb-4">Drag and drop your retinal image here</p>
            <label className="cursor-pointer">
              <span className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition">
                Select Image
              </span>
              <input
                type="file"
                accept="image/jpeg,image/png,image/tiff"
                onChange={handleFileSelect}
                className="hidden"
              />
            </label>
            <p className="text-sm text-gray-500 mt-4">Supported formats: JPEG, PNG, TIFF</p>
          </div>

          {/* Preview */}
          {preview && (
            <div className="mb-8">
              <h3 className="text-lg font-semibold text-gray-800 mb-4">Preview</h3>
              <img
                src={preview}
                alt="Preview"
                className="max-w-full h-64 object-cover rounded-lg mx-auto"
              />
              <p className="text-sm text-gray-600 mt-2">File: {file?.name}</p>
            </div>
          )}

          {/* Status Messages */}
          {uploadStatus === 'success' && (
            <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-8 flex items-center">
              <CheckCircle className="w-5 h-5 text-green-600 mr-3" />
              <p className="text-green-800">{message}</p>
            </div>
          )}

          {uploadStatus === 'error' && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-8 flex items-center">
              <AlertCircle className="w-5 h-5 text-red-600 mr-3" />
              <p className="text-red-800">{message}</p>
            </div>
          )}

          {/* Upload Button */}
          <button
            onClick={handleUpload}
            disabled={!file || uploading}
            className="w-full bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 disabled:bg-gray-400 transition font-medium"
          >
            {uploading ? 'Uploading...' : 'Upload and Analyze'}
          </button>
        </div>

        {/* Information Box */}
        <div className="mt-8 bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h3 className="font-semibold text-blue-900 mb-3">What happens next?</h3>
          <ul className="space-y-2 text-blue-800 text-sm">
            <li>✓ Your image will be analyzed by our AI models</li>
            <li>✓ Detection for diabetic retinopathy, glaucoma, and macular degeneration</li>
            <li>✓ You'll receive a detailed report within minutes</li>
            <li>✓ Plain-English summary will be generated</li>
            <li>✓ Referral recommendations if needed</li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default ScanUploadPage;
