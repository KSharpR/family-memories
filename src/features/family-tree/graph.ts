import type { MemoryItem } from "../../domain/memory";

export interface PeopleGraphNode {
  id: string;
  label: string;
  count: number;
}

export interface PeopleGraphLink {
  source: string;
  target: string;
  count: number;
}

export interface PeopleGraph {
  nodes: PeopleGraphNode[];
  links: PeopleGraphLink[];
}

export function buildPeopleGraph(memories: MemoryItem[]): PeopleGraph {
  const nodeCounts = new Map<string, number>();
  const linkCounts = new Map<string, PeopleGraphLink>();

  for (const memory of memories) {
    const people = Array.from(new Set(memory.people)).sort(compareZhCn);

    for (const person of people) {
      nodeCounts.set(person, (nodeCounts.get(person) ?? 0) + 1);
    }

    for (let sourceIndex = 0; sourceIndex < people.length; sourceIndex++) {
      for (let targetIndex = sourceIndex + 1; targetIndex < people.length; targetIndex++) {
        const source = people[sourceIndex];
        const target = people[targetIndex];
        const key = relationshipKey(source, target);
        const link = linkCounts.get(key);

        if (link) {
          link.count += 1;
        } else {
          linkCounts.set(key, { source, target, count: 1 });
        }
      }
    }
  }

  return {
    nodes: Array.from(nodeCounts, ([person, count]) => ({
      id: person,
      label: person,
      count
    })).sort((first, second) => second.count - first.count || compareZhCn(first.label, second.label)),
    links: Array.from(linkCounts.values()).sort(
      (first, second) =>
        second.count - first.count ||
        compareZhCn(first.source, second.source) ||
        compareZhCn(first.target, second.target)
    )
  };
}

function compareZhCn(first: string, second: string): number {
  return first.localeCompare(second, "zh-CN");
}

function relationshipKey(source: string, target: string): string {
  return JSON.stringify([source, target]);
}
