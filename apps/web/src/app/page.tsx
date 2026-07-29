import ReportMap from "@/components/ReportMap";

export default function Home() {
  return (
    <div className="flex h-dvh flex-col">
      <header className="flex items-center justify-between border-b border-zinc-200 px-4 py-3 dark:border-zinc-800">
        <h1 className="text-lg font-semibold">
          Namma Kasa <span className="text-zinc-500">ನಮ್ಮ ಕಸ</span>
        </h1>
        <p className="text-sm text-zinc-500">Bengaluru waste watch</p>
      </header>
      <main className="min-h-0 flex-1">
        <ReportMap />
      </main>
    </div>
  );
}
