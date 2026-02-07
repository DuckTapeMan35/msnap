import { useState } from "react";
import { ModeToggle } from "./ModeToggle";
import { SelectionTabs } from "./SelectionTabs";
import { CaptureButton } from "./CaptureButton";
import type { CaptureMode, SelectionType } from "@/types/capture";

export function CaptureWindow() {
  const [mode, setMode] = useState<CaptureMode>('screenshot');
  const [selectionType, setSelectionType] = useState<SelectionType>('region');

  const handleCapture = () => {
    console.log('Capture:', { mode, selectionType });
  };

  return (
    <div className="w-full h-full flex items-center justify-center [padding:0.375rem]">
      <div className="w-full rounded-xl bg-card border shadow-xl [padding:0.75rem]">
        <div className="flex flex-col gap-3">
          <ModeToggle value={mode} onChange={setMode} />
          <SelectionTabs value={selectionType} onChange={setSelectionType} />
          <CaptureButton mode={mode} onClick={handleCapture} />
        </div>
      </div>
    </div>
  );
}
