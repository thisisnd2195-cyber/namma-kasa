import Link from "next/link";

const SECTIONS = [
  { href: "/dashboard", title: "Today", body: "Coverage, complaints, missed pickups" },
  { href: "/wards", title: "Wards", body: "Boundaries, import, ward admins" },
  { href: "/routes", title: "Routes", body: "Service areas, schedules, passes" },
  { href: "/fleet", title: "Fleet", body: "Autos, drivers, assignments" },
  { href: "/live", title: "Live", body: "Active trips and tracking health" },
  { href: "/review-queue", title: "Review queue", body: "Unmapped households" },
  { href: "/complaints", title: "Complaints", body: "Resident reports and SLAs" },
];

export default function AdminHome() {
  return (
    <main className="mx-auto max-w-5xl px-6 py-12">
      <h1 className="text-2xl font-medium text-[#202124]">Namma Kasa admin</h1>
      <p className="mt-2 text-sm text-[#5F6368]">
        Ward, route, and fleet administration for door-to-door waste collection.
      </p>
      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {SECTIONS.map((section) => (
          <Link
            key={section.href}
            href={section.href}
            className="rounded-xl border border-[#DADCE0] p-5 transition-colors hover:bg-[#F8F9FA]"
          >
            <h2 className="text-base font-medium text-[#202124]">{section.title}</h2>
            <p className="mt-1 text-sm text-[#5F6368]">{section.body}</p>
          </Link>
        ))}
      </div>
    </main>
  );
}
