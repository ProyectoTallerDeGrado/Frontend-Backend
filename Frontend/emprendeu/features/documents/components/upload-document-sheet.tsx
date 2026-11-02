"use client";

import { useState } from "react";
import { Upload } from "lucide-react";

import { Field, FormError, FormSheet, SheetFooter, inputClass, useRunner } from "@/components/forms/form-bits";

import { DOCUMENT_EXTENSIONS, DOCUMENT_MAX_MB, validateDocumentFile } from "../schemas/documents-schemas";
import { uploadDocumentAction } from "../server/actions";

function Form({ ventures, defaultVenture, onDone }: { ventures: { id: number; name: string }[]; defaultVenture: string; onDone: () => void }) {
  const [file, setFile] = useState<File | null>(null);
  const [venture, setVenture] = useState(defaultVenture);
  const [localError, setLocalError] = useState<string | null>(null);
  const { pending, error, run } = useRunner(onDone);
  return (
    <form
      noValidate
      className="flex min-h-0 flex-1 flex-col"
      onSubmit={(e) => {
        e.preventDefault();
        const problem = validateDocumentFile(file) ?? (venture ? null : "Elige el emprendimiento.");
        setLocalError(problem);
        if (problem || !file) return;
        const data = new FormData();
        data.append("file", file);
        data.append("emprendimiento_id", venture);
        run(() => uploadDocumentAction(data));
      }}
    >
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        <Field label="Emprendimiento" hint="Un asesor solo puede subir a los emprendimientos que tiene asignados.">
          {(id) => (
            <select id={id} value={venture} onChange={(e) => setVenture(e.target.value)} className={inputClass}>
              <option value="">Elige un emprendimiento</option>
              {ventures.map((v) => (
                <option key={v.id} value={v.id}>
                  {v.name}
                </option>
              ))}
            </select>
          )}
        </Field>
        <Field label="Archivo" hint={`${DOCUMENT_EXTENSIONS.join(", ")}. Máximo ${DOCUMENT_MAX_MB} MB.`}>
          {(id) => (
            <input
              id={id}
              type="file"
              accept={DOCUMENT_EXTENSIONS.join(",")}
              onChange={(e) => setFile(e.target.files?.[0] ?? null)}
              className="block min-h-12 w-full rounded-xl border-[1.5px] border-border-strong bg-card px-3 py-2.5 text-sm file:mr-3 file:rounded-lg file:border-0 file:bg-blue-50 file:px-3 file:py-2 file:font-semibold file:text-primary"
            />
          )}
        </Field>
        <FormError message={localError ?? error} />
      </div>
      <SheetFooter pending={pending} label="Subir documento" />
    </form>
  );
}

export function UploadDocumentSheet({ ventures, defaultVenture }: { ventures: { id: number; name: string }[]; defaultVenture: string }) {
  return (
    <FormSheet
      title="Subir documento"
      trigger={
        <>
          <Upload aria-hidden="true" className="size-[18px]" strokeWidth={2.4} />
          Subir documento
        </>
      }
    >
      {(close) => <Form ventures={ventures} defaultVenture={defaultVenture} onDone={close} />}
    </FormSheet>
  );
}
