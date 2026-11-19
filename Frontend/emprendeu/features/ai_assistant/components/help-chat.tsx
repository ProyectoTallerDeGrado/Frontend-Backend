"use client";

import { usePathname } from "next/navigation";
import { Fragment, useEffect, useMemo, useRef, useState, useTransition, type ReactNode } from "react";
import { MessageCircleQuestion, SendHorizontal, Sparkles, Trash2, X } from "lucide-react";

import { cn } from "@/lib/utils";

import { HELP_MESSAGE_MAX } from "../schemas/ai-schemas";
import { askHelpAction } from "../server/actions";
import { useHelpChatStore } from "../stores/help-chat-store";
import { helpSuggestionsFor } from "./help-suggestions";

/** `**negrita**` dentro de una línea, sin interpretar HTML. */
function inline(text: string): ReactNode[] {
  return text.split(/(\*\*[^*]+\*\*)/g).map((part, i) =>
    part.startsWith("**") && part.endsWith("**") ? <strong key={i}>{part.slice(2, -2)}</strong> : <Fragment key={i}>{part}</Fragment>,
  );
}

/** Markdown mínimo de las respuestas: párrafos, listas numeradas o con viñetas y negritas. */
function RichText({ text }: { text: string }) {
  const blocks: ReactNode[] = [];
  let list: { ordered: boolean; items: string[] } | null = null;
  const flush = () => {
    if (!list) return;
    const Tag = list.ordered ? "ol" : "ul";
    blocks.push(
      <Tag key={blocks.length} className={cn("flex flex-col gap-1 pl-5", list.ordered ? "list-decimal" : "list-disc")}>
        {list.items.map((item, i) => (
          <li key={i}>{inline(item)}</li>
        ))}
      </Tag>,
    );
    list = null;
  };
  for (const raw of text.split("\n")) {
    const line = raw.trim();
    const ordered = /^\d+[.)]\s+(.*)$/.exec(line);
    const bullet = /^[-*•]\s+(.*)$/.exec(line);
    if (ordered || bullet) {
      const isOrdered = Boolean(ordered);
      if (list && list.ordered !== isOrdered) flush();
      list ??= { ordered: isOrdered, items: [] };
      list.items.push((ordered ?? bullet)![1]);
      continue;
    }
    flush();
    if (line) blocks.push(<p key={blocks.length}>{inline(line)}</p>);
  }
  flush();
  return <div className="flex flex-col gap-2">{blocks}</div>;
}

/**
 * Botón flotante de ayuda (abajo a la derecha) con un chat que explica cómo usar el panel.
 * `extra` va al pie del panel (p. ej. «Ver tutorial», que aporta la feature `auth`).
 */
export function HelpChat({ extra, userId }: { extra?: ReactNode; userId: number }) {
  const pathname = usePathname();
  const { ownerId, open, pending, messages: stored, setOpen, add, setPending, clear, bind } = useHelpChatStore();
  // La conversación guardada puede ser de otra persona que usó este navegador: sin dueño no se muestra nada.
  const owned = ownerId === userId;
  const messages = useMemo(() => (owned ? stored : []), [owned, stored]);

  useEffect(() => {
    bind(userId);
  }, [userId, bind]);
  const [draft, setDraft] = useState("");
  const [, startTransition] = useTransition();
  const listRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const suggestions = helpSuggestionsFor(pathname);

  useEffect(() => {
    listRef.current?.scrollTo({ top: listRef.current.scrollHeight, behavior: "smooth" });
  }, [messages, pending]);

  useEffect(() => {
    if (!open) return;
    inputRef.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, setOpen]);

  function send(question: string) {
    const text = question.trim();
    if (!text || pending || !owned) return;
    const history = messages.map(({ role, text: t }) => ({ role, text: t }));
    add({ role: "user", text });
    setDraft("");
    setPending(true);
    startTransition(async () => {
      const result = await askHelpAction(text, history, pathname);
      // Si cambió la sesión mientras esperaba, la respuesta no pertenece a la conversación actual.
      if (useHelpChatStore.getState().ownerId !== userId) return;
      setPending(false);
      if (result.ok) add({ role: "assistant", text: result.reply.respuesta, origin: result.reply.origen });
      else add({ role: "assistant", text: result.message });
    });
  }

  return (
    <>
      {open && (
        <section
          id="help-chat"
          role="dialog"
          aria-label="Asistente de ayuda"
          className="help-chat-in fixed right-4 bottom-24 z-40 flex h-[min(560px,calc(100dvh-8rem))] w-[min(390px,calc(100vw-2rem))] flex-col overflow-hidden rounded-[20px] border border-border bg-card text-card-foreground shadow-overlay sm:right-6"
        >
          <header className="flex items-start gap-3 bg-navy-950 px-4 py-3.5 text-white">
            <span aria-hidden="true" className="flex size-9 shrink-0 items-center justify-center rounded-full bg-primary">
              <Sparkles className="size-[18px]" />
            </span>
            <div className="min-w-0 flex-1">
              <h2 className="font-heading text-[15px] leading-tight font-bold">Asistente de ayuda</h2>
              <p className="text-xs text-on-navy-faint">Pregúntame cómo usar el sistema</p>
            </div>
            {messages.length > 0 && (
              <button
                type="button"
                onClick={clear}
                aria-label="Borrar la conversación"
                className="flex size-9 items-center justify-center rounded-lg text-on-navy-muted outline-none hover:bg-white/10 hover:text-white focus-visible:ring-3 focus-visible:ring-white/40"
              >
                <Trash2 aria-hidden="true" className="size-4" />
              </button>
            )}
            <button
              type="button"
              onClick={() => setOpen(false)}
              aria-label="Cerrar la ayuda"
              className="flex size-9 items-center justify-center rounded-lg text-on-navy-muted outline-none hover:bg-white/10 hover:text-white focus-visible:ring-3 focus-visible:ring-white/40"
            >
              <X aria-hidden="true" className="size-5" />
            </button>
          </header>

          <div ref={listRef} aria-live="polite" className="flex flex-1 flex-col gap-3 overflow-y-auto px-4 py-4 text-sm">
            <div className="max-w-[88%] rounded-2xl rounded-tl-md bg-muted px-3.5 py-2.5">
              ¡Hola! Soy el asistente de EmprendeU. Te explico dónde está cada cosa y cómo hacerla paso a paso.
            </div>
            {messages.map((m) => (
              <div
                key={m.id}
                className={cn(
                  "max-w-[88%] rounded-2xl px-3.5 py-2.5 leading-relaxed",
                  m.role === "user" ? "self-end rounded-tr-md bg-primary text-primary-foreground" : "rounded-tl-md bg-muted",
                )}
              >
                {m.role === "assistant" ? <RichText text={m.text} /> : m.text}
                {m.origin === "guia" && (
                  <p className="mt-2 text-[11.5px] text-muted-foreground">Respuesta de la guía rápida (IA no disponible ahora).</p>
                )}
              </div>
            ))}
            {pending && (
              <div className="flex w-fit items-center gap-1 rounded-2xl rounded-tl-md bg-muted px-4 py-3" aria-label="Escribiendo">
                {[0, 1, 2].map((i) => (
                  <span key={i} className="help-dot size-1.5 rounded-full bg-muted-foreground" style={{ animationDelay: `${i * 150}ms` }} />
                ))}
              </div>
            )}
            {messages.length === 0 && !pending && (
              <div className="mt-1 flex flex-col items-start gap-2">
                {suggestions.map((q) => (
                  <button
                    key={q}
                    type="button"
                    onClick={() => send(q)}
                    className="rounded-full border border-border-strong px-3 py-1.5 text-left text-[13px] font-semibold text-primary outline-none transition-colors hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-ring/40"
                  >
                    {q}
                  </button>
                ))}
              </div>
            )}
          </div>

          <form
            onSubmit={(e) => {
              e.preventDefault();
              send(draft);
            }}
            className="flex items-end gap-2 border-t border-border px-3 py-3"
          >
            <label htmlFor="help-input" className="sr-only">
              Escribe tu pregunta
            </label>
            <textarea
              id="help-input"
              ref={inputRef}
              rows={1}
              value={draft}
              maxLength={HELP_MESSAGE_MAX}
              onChange={(e) => setDraft(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  send(draft);
                }
              }}
              placeholder="¿Cómo registro una sesión?"
              className="max-h-28 min-h-11 flex-1 resize-none rounded-xl border border-input bg-background px-3 py-2.5 text-sm outline-none focus-visible:border-primary focus-visible:ring-4 focus-visible:ring-ring/20"
            />
            <button
              type="submit"
              disabled={pending || !draft.trim()}
              aria-label="Enviar"
              className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-primary text-primary-foreground outline-none transition-colors hover:bg-primary-hover focus-visible:ring-3 focus-visible:ring-ring/40 disabled:opacity-50"
            >
              <SendHorizontal aria-hidden="true" className="size-[18px]" />
            </button>
          </form>
          {extra && (
            // Lo que va al pie (p. ej. «Ver tutorial») cierra el chat para dejar ver la pantalla.
            <div onClick={() => setOpen(false)} className="flex justify-center border-t border-border bg-surface-head px-3 py-2">
              {extra}
            </div>
          )}
        </section>
      )}

      <button
        type="button"
        data-tour="help"
        onClick={() => setOpen(!open)}
        aria-expanded={open}
        aria-controls="help-chat"
        aria-label={open ? "Cerrar la ayuda" : "Abrir la ayuda"}
        className="fixed right-4 bottom-4 z-40 flex size-14 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-overlay outline-none transition-[transform,background] duration-200 hover:scale-105 hover:bg-primary-hover focus-visible:ring-4 focus-visible:ring-ring/40 sm:right-6 sm:bottom-6"
      >
        {open ? <X aria-hidden="true" className="size-6" /> : <MessageCircleQuestion aria-hidden="true" className="size-6" />}
      </button>
    </>
  );
}
