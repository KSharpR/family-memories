import { useMemo } from "react";
import type { MemoryItem } from "../../domain/memory";
import { buildPeopleGraph, type PeopleGraphNode } from "./graph";

interface FamilyTreeViewProps {
  memories: MemoryItem[];
}

interface PositionedNode extends PeopleGraphNode {
  x: number;
  y: number;
}

const svgWidth = 720;
const svgHeight = 460;
const centerX = svgWidth / 2;
const centerY = svgHeight / 2;
const minGraphRadius = 155;
const maxGraphRadius = 210;

export function FamilyTreeView({ memories }: FamilyTreeViewProps) {
  const graph = useMemo(() => buildPeopleGraph(memories), [memories]);
  const radius = nodeRadius(graph.nodes.length);
  const graphRadius = layoutRadius(graph.nodes.length, radius);
  const positionedNodes = useMemo(
    () => positionNodes(graph.nodes, graphRadius),
    [graph.nodes, graphRadius]
  );
  const nodeById = new Map(positionedNodes.map((node) => [node.id, node]));
  const fontSize = graph.nodes.length > 12 ? 12 : 17;

  if (graph.nodes.length === 0) {
    return (
      <section className="empty-state family-tree-empty">
        <h2>还没有人物关系</h2>
        <p>在照片中添加人物标签后，这里会显示同框关系。</p>
      </section>
    );
  }

  return (
    <section className="family-tree-view">
      <div className="family-tree-intro">
        <h2>人物同框关系</h2>
        <p>这里根据照片中的人物标签整理同框次数，只表示共同出现在照片中，不代表法律或家庭关系。</p>
      </div>

      <div className="family-tree-graph-frame">
        <svg
          className="family-tree-graph"
          role="img"
          aria-label="人物同框关系图"
          viewBox={`0 0 ${svgWidth} ${svgHeight}`}
        >
          <title>人物同框关系图</title>
          <desc>{describeGraph(graph.nodes.length, graph.links.length)}</desc>
          <g className="family-tree-links">
            {graph.links.map((link) => {
              const source = nodeById.get(link.source);
              const target = nodeById.get(link.target);

              if (!source || !target) {
                return null;
              }

              return (
                <line
                  key={relationshipKey(link.source, link.target)}
                  data-testid="family-tree-link"
                  data-link-key={relationshipKey(link.source, link.target)}
                  x1={source.x}
                  y1={source.y}
                  x2={target.x}
                  y2={target.y}
                  strokeWidth={Math.min(8, 1.5 + link.count)}
                />
              );
            })}
          </g>

          <g className="family-tree-nodes">
            {positionedNodes.map((node) => (
              <g key={node.id}>
                <circle
                  data-testid="family-tree-node-circle"
                  cx={node.x}
                  cy={node.y}
                  r={radius}
                />
                <text
                  x={node.x}
                  y={node.y}
                  textAnchor="middle"
                  dominantBaseline="central"
                  fontSize={fontSize}
                >
                  {node.label}
                </text>
              </g>
            ))}
          </g>
        </svg>
      </div>

      <div className="family-tree-summary">
        <h3>同框摘要</h3>
        <ul aria-label="人物同框关系摘要">
          {graph.nodes.map((node) => (
            <li key={`node-${node.id}`}>
              {node.label}：{node.count} 张照片
            </li>
          ))}
          {graph.links.map((link) => (
            <li key={`link-${relationshipKey(link.source, link.target)}`}>
              {link.source} 和 {link.target}：{link.count} 次同框
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}

function positionNodes(nodes: PeopleGraphNode[], graphRadius: number): PositionedNode[] {
  if (nodes.length === 1) {
    return [{ ...nodes[0], x: centerX, y: centerY }];
  }

  return nodes.map((node, index) => {
    const angle = (index / nodes.length) * Math.PI * 2 - Math.PI / 2;

    return {
      ...node,
      x: centerX + Math.cos(angle) * graphRadius,
      y: centerY + Math.sin(angle) * graphRadius
    };
  });
}

function nodeRadius(nodeCount: number): number {
  if (nodeCount >= 32) {
    return 14;
  }
  if (nodeCount >= 18) {
    return 16;
  }
  if (nodeCount >= 12) {
    return 24;
  }
  return 38;
}

function describeGraph(nodeCount: number, linkCount: number): string {
  return `共有 ${nodeCount} 个人物节点和 ${linkCount} 条同框关系。详细关系见图下方同框摘要。`;
}

function layoutRadius(nodeCount: number, radius: number): number {
  if (nodeCount <= 1) {
    return 0;
  }

  const minimumRadius = radius / Math.sin(Math.PI / nodeCount);
  return Math.min(maxGraphRadius, Math.max(minGraphRadius, minimumRadius));
}

function relationshipKey(source: string, target: string): string {
  return JSON.stringify([source, target]);
}
