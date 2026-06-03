import cv2
import numpy as np
from PIL import Image
import io
from typing import Tuple


class ImagePreprocessor:
    """Preprocesses retinal fundus images for ML model inference"""
    
    @staticmethod
    def resize_image(image: np.ndarray, target_size: Tuple[int, int] = (512, 512)) -> np.ndarray:
        """Resize image to target size"""
        return cv2.resize(image, target_size, interpolation=cv2.INTER_AREA)
    
    @staticmethod
    def normalize_image(image: np.ndarray) -> np.ndarray:
        """Normalize image to [0, 1] range"""
        return image.astype(np.float32) / 255.0
    
    @staticmethod
    def apply_clahe(image: np.ndarray) -> np.ndarray:
        """Apply Contrast Limited Adaptive Histogram Equalization (CLAHE)"""
        if len(image.shape) == 3:
            # Convert BGR to LAB
            lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
            l, a, b = cv2.split(lab)
            
            # Apply CLAHE to L channel
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
            l_clahe = clahe.apply(l)
            
            # Merge channels back
            lab_clahe = cv2.merge([l_clahe, a, b])
            image_clahe = cv2.cvtColor(lab_clahe, cv2.COLOR_LAB2BGR)
            return image_clahe
        return image
    
    @staticmethod
    def remove_noise(image: np.ndarray) -> np.ndarray:
        """Remove noise using bilateral filter"""
        return cv2.bilateralFilter(image, 9, 75, 75)
    
    @staticmethod
    def preprocess(image_data: bytes) -> np.ndarray:
        """
        Full preprocessing pipeline for retinal images
        
        Args:
            image_data: Raw image bytes
            
        Returns:
            Preprocessed image array
        """
        # Load image from bytes
        image = Image.open(io.BytesIO(image_data))
        image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
        
        # Apply preprocessing steps
        image = ImagePreprocessor.resize_image(image)
        image = ImagePreprocessor.apply_clahe(image)
        image = ImagePreprocessor.remove_noise(image)
        image = ImagePreprocessor.normalize_image(image)
        
        return image
    
    @staticmethod
    def assess_image_quality(image: np.ndarray) -> Tuple[float, str]:
        """
        Assess quality of retinal image
        
        Returns:
            Tuple of (quality_score, quality_status)
        """
        # Convert to grayscale
        if len(image.shape) == 3:
            gray = cv2.cvtColor((image * 255).astype(np.uint8), cv2.COLOR_BGR2GRAY)
        else:
            gray = (image * 255).astype(np.uint8)
        
        # Calculate Laplacian variance (measure of blur)
        laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
        
        # Determine quality status based on variance
        if laplacian_var > 500:
            return 1.0, "good"
        elif laplacian_var > 200:
            return 0.7, "acceptable"
        else:
            return 0.3, "poor"
