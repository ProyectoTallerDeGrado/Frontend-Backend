"use client";

import { useState } from "react";
import { Upload } from "lucide-react";

import { Field, FormError, FormSheet, SheetFooter, useRunner } from "@/components/forms/form-bits";

import { DOCUMENT_EXTENSIONS, DOCUMENT_MAX_MB, validateDocumentFile } from "../schemas/documents-schemas";
import { uploadDocumentAction } from "../server/actions";

function Form({ ventureId, onDone }: { ventureId: number; onDone: () => void }) {
  const [file, setFile] = useState<File | null>(null);
  const [localError, setLocalError] = useState<string | null>(null);
  const { pending, error, run } = useRunner(onDone);
  return (
    <form
      noValidate
      className="flex min-h-0 flex-1 flex-col"
      onSubmit={(e) => {
        e.preventDefault();
        const problem = validateDocumentFile(file);
        setLocalError(problem);
        if (problem || !file) return;
        const data = new FormData();
        data.append("file", file);
        run(() => uploadDocumentAction(ventureId, data));
      }}
    >
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        <Field label="Archivo" hint={`Formatos: ${DOCUMENT_EXTENSIONS.join(", ")}. Máximo ${DOCUMENT_MAX_MB} MB.`}>
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

export function UploadDocumentSheet({ ventureId }: { ventureId: number }) {
  return (
    <FormSheet
      title="Subir documento"
      trigger={
        <>
          <Upload aria-hidden="true" className="size-[18px]" /> Subir documento
        </>
      }
    >
      {(close) => <Form ventureId={ventureId} onDone={close} />}
    </FormSheet>
  );
}
