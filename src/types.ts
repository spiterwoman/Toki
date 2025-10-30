export type Task = {
  id: string;
  title: string;
  time?: string;
  tag?: "Work" | "Personal" | "School";
  priority?: "low" | "medium" | "high";
  done?: boolean;
};

export type CalendarEvent = {
  id: string;
  title: string;
  date: string; // yyyy-mm-dd
  time?: string;
};

export type Garage = {
  id: string;
  name: string;
  available: number; // available spots
  capacity: number;
  status: "Available" | "Limited" | "Full";
  note?: string;
};
