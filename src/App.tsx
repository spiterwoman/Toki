import { Route, Routes, Navigate, useNavigate } from "react-router-dom";
import LoginPage from "./pages/LoginPage";
import SignupPage from "./pages/SignupPage";
import VerificationPage from "./pages/VerificationPage";
import DailySummaryPage from "./pages/DailySummaryPage";
import CalendarPage from "./pages/CalendarPage";
import TasksPage from "./pages/TasksPage";
import RemindersPage from "./pages/RemindersPage";
import WeatherPage from "./pages/WeatherPage";
import NasaPhotoPage from "./pages/NasaPhotoPage";
import UCFParkingPage from "./pages/UCFParkingPage";
import SettingsPage from "./pages/SettingsPage";

export default function App(){
  const navigate = useNavigate();

  return (
    <Routes>
      <Route path="/" element={<Navigate to="/login" replace />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/signup" element={<SignupPage />} />
      <Route path="/verify" element={<VerificationPage onVerify={() => { navigate("/daily-summary"); return true; }}/>} />
      <Route path="/daily-summary" element={<DailySummaryPage />} />
      <Route path="/calendar" element={<CalendarPage />} />
      <Route path="/tasks" element={<TasksPage />} />
      <Route path="/reminders" element={<RemindersPage />} />
      <Route path="/weather" element={<WeatherPage />} />
      <Route path="/nasa-photo" element={<NasaPhotoPage />} />
      <Route path="/parking" element={<UCFParkingPage />} />
      <Route path="/settings" element={<SettingsPage />} />
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}
