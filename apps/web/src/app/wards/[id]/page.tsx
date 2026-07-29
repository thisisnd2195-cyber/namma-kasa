interface Props {
  params: Promise<{ id: string }>;
}

export default async function WardPage({ params }: Props) {
  const { id } = await params;
  return (
    <main className="mx-auto max-w-2xl p-6">
      <h1 className="text-xl font-semibold">Ward {id}</h1>
      <p className="mt-2 text-zinc-500">
        Ward scorecard — open reports, median resolution time, and trends will land here.
      </p>
    </main>
  );
}
