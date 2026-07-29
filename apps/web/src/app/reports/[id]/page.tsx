interface Props {
  params: Promise<{ id: string }>;
}

export default async function ReportDetailPage({ params }: Props) {
  const { id } = await params;
  return (
    <main className="mx-auto max-w-2xl p-6">
      <h1 className="text-xl font-semibold">Report {id}</h1>
      <p className="mt-2 text-zinc-500">
        Report detail — status timeline, photos, and verification will land here.
      </p>
    </main>
  );
}
