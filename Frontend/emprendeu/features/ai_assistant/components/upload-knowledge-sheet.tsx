"use client";

import { useState } from "react";
import { Upload } from "lucide-react";

import { Field, FormError, FormSheet, SheetFooter, inputClass, textareaClass, useRunner } from "@/components/forms/form-bits";

import { KNOWLEDGE_EXTENSIONS, KNOWLEDGE_MAX_MB, validateKnowledgeFile } from "../schemas/ai-schemas";
import { uploadKnowledgeAction } from "../server/actions";

function Form({ onDone }: { onDone: () => void }) {
  const [file, setFile] = useState<File | null>(null);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [source, setSource] = useState("");
  const [localError, setLocalError] = useState<string | null>(null);
  const { pending, error, run } = useRunner(onDone);

  return (
    <form
      noValidate
      className="flex min-h-0 flex-1 flex-col"
      onSubmit={(e) => {
        e.preventDefault();
        const problem = validateKnowledgeFile(file) ?? (title.trim() ? null : "Escribe un título para el documento.");
        setLocalError(problem);
        if (problem || !file) return;
        const data = new FormData();
        data.append("file", file);
        data.append("titulo", title);
        data.append("descripcion", description);
        data.append("fuente", source);
        run(() => uploadKnowledgeAction(data));
      }}
    >
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        <Field label="Archivo" hint={`Formatos: ${KNOWLEDGE_EXTENSIONS.join(", ")}. Máximo ${KNOWLEDGE_MAX_MB} MB.`}>
          {(id) => (
            <input
              id={id}
              type="file"
              accept={KNOWLEDGE_EXTENSIONS.join(",")}
              onChange={(e) => {
                const chosen = e.target.files?.[0] ?? null;
                setFile(chosen);
                if (chosen && !title) setTitle(chosen.name.replace(/\.[^.]+$/, ""));
              }}
              className="block min-h-12 w-full rounded-xl border-[1.5px] border-border-strong bg-card px-3 py-2.5 text-sm file:mr-3 file:rounded-lg file:border-0 file:bg-blue-50 file:px-3 file:py-2 file:font-semibold file:text-primary"
            />
          )}
        </Field>
        <Field label="Título">
          {(id) => <input id={id} value={title} onChange={(e) => setTitle(e.target.value)} className={inputClass} />}
        </Field>
        <Field label="Descripción" hint="Opcional.">
          {(id) => <textarea id={id} value={description} onChange={(e) => setDescription(e.target.value)} className={textareaClass} />}
        </Field>
        <Field label="Fuente" hint="Opcional. Si la dejas vacía se usa el nombre del archivo.">
          {(id) => <input id={id} value={source} onChange={(e) => setSource(e.target.value)} className={inputClass} />}
        </Field>
        <p className="rounded-xl bg-blue-50 px-4 py-3 text-[13px] leading-snug">
          Al subirlo se divide en fragmentos y se calculan sus embeddings; puede tardar unos segundos. Hasta que
          termine, el documento aparece como «Procesando».
        </p>
        <FormError message={localError ?? error} />
      </div>
      <SheetFooter pending={pending} label="Subir y procesar" />
    </form>
  );
}

export function UploadKnowledgeSheet() {
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
      {(close) => <Form onDone={close} />}
    </FormSheet>
  );
}
