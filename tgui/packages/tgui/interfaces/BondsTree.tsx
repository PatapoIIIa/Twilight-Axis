import { NoticeBox } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type EdgeEntry = {
  name: string;
  accent: string;
  outLabel: string;
  outProgress: number;
  inLabel: string | null;
  inProgress: number;
  inAccent: string;
};

type SelfInfo = {
  name: string;
  accent: string;
};

type Data = {
  self: SelfInfo | null;
  edges: EdgeEntry[];
};

const WIDTH = 720;
const HEIGHT = 640;
const CENTER_X = WIDTH / 2;
const CENTER_Y = HEIGHT / 2;
const RING = 210;
const BAR_LENGTH = 74;
const BAR_HEIGHT = 7;

// Nodes sit on a ring around the viewer. With more than a dozen bonds the ring grows a second
// lap outward so labels keep room to breathe.
function ringRadius(index: number, total: number) {
  if (total <= 12) return RING;
  return index % 2 === 0 ? RING - 45 : RING + 55;
}

export const BondsTree = () => {
  const { data } = useBackend<Data>();
  const { self, edges = [] } = data;

  if (!self || !edges.length) {
    return (
      <Window title="Древо связей" width={WIDTH} height={HEIGHT}>
        <Window.Content style={{ backgroundImage: 'none' }}>
          <NoticeBox>Вы пока ни к кому ничего не испытываете.</NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  const total = edges.length;

  return (
    <Window title="Древо связей" width={WIDTH} height={HEIGHT}>
      <Window.Content style={{ backgroundImage: 'none' }}>
        <svg
          viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
          style={{ width: '100%', height: '100%' }}
        >
          {edges.map((edge, index) => {
            const angle = (index / total) * Math.PI * 2 - Math.PI / 2;
            const radius = ringRadius(index, total);
            const x = CENTER_X + Math.cos(angle) * radius;
            const y = CENTER_Y + Math.sin(angle) * radius;
            const midX = (CENTER_X + x) / 2;
            const midY = (CENTER_Y + y) / 2;
            const outWidth = Math.max(0, Math.min(1, edge.outProgress));
            const inWidth = Math.max(0, Math.min(1, edge.inProgress));

            return (
              <g key={index}>
                <line
                  x1={CENTER_X}
                  y1={CENTER_Y}
                  x2={x}
                  y2={y}
                  stroke={edge.accent}
                  strokeWidth={2}
                  opacity={0.55}
                />

                <text
                  x={midX}
                  y={midY - 12}
                  textAnchor="middle"
                  fill={edge.accent}
                  fontSize="13"
                  fontWeight="bold"
                >
                  {edge.outLabel}
                </text>

                {/* Two-sided bar: left half is how they feel about you, right half is you
                    about them. Each half fills toward its own next stage. */}
                <rect
                  x={midX - BAR_LENGTH}
                  y={midY}
                  width={BAR_LENGTH * 2}
                  height={BAR_HEIGHT}
                  fill="#00000055"
                  rx={2}
                />
                <rect
                  x={midX - BAR_LENGTH * inWidth}
                  y={midY}
                  width={BAR_LENGTH * inWidth}
                  height={BAR_HEIGHT}
                  fill={edge.inAccent}
                  rx={2}
                />
                <rect
                  x={midX}
                  y={midY}
                  width={BAR_LENGTH * outWidth}
                  height={BAR_HEIGHT}
                  fill={edge.accent}
                  rx={2}
                />
                <line
                  x1={midX}
                  y1={midY - 2}
                  x2={midX}
                  y2={midY + BAR_HEIGHT + 2}
                  stroke="#e0e0e0"
                  strokeWidth={1}
                />

                {!!edge.inLabel && (
                  <text
                    x={midX}
                    y={midY + BAR_HEIGHT + 14}
                    textAnchor="middle"
                    fill={edge.inAccent}
                    fontSize="11"
                    opacity={0.85}
                  >
                    {edge.inLabel} &#8592;
                  </text>
                )}

                <circle cx={x} cy={y} r={30} fill="#1c1c1c" stroke={edge.accent} strokeWidth={2} />
                <text
                  x={x}
                  y={y + 4}
                  textAnchor="middle"
                  fill="#e8e8e8"
                  fontSize="11"
                >
                  {edge.name.length > 12 ? `${edge.name.slice(0, 11)}…` : edge.name}
                </text>
              </g>
            );
          })}

          <circle
            cx={CENTER_X}
            cy={CENTER_Y}
            r={40}
            fill="#241f16"
            stroke={self.accent}
            strokeWidth={3}
          />
          <text
            x={CENTER_X}
            y={CENTER_Y + 4}
            textAnchor="middle"
            fill={self.accent}
            fontSize="12"
            fontWeight="bold"
          >
            {self.name.length > 14 ? `${self.name.slice(0, 13)}…` : self.name}
          </text>
        </svg>
      </Window.Content>
    </Window>
  );
};
