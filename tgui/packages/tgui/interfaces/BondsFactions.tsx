import { Box, NoticeBox, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type FactionInfo = {
  name: string;
  accent: string;
};

type MapNode = {
  id: string;
  name: string;
  accent: string;
  own: number | boolean;
};

type MapEdge = {
  a: string;
  b: string;
  label: string;
  accent: string;
  warmth: number;
  weight: number;
};

type HouseEntry = {
  name: string;
  label: string;
  labelAccent: string;
  intensity: string;
  incidents: number;
};

type StanceEntry = {
  name: string;
  accent: string;
  label: string;
  labelAccent: string;
  intensity: string;
};

type Data = {
  ownFaction: FactionInfo | null;
  map: { nodes: MapNode[]; edges: MapEdge[] };
  ownHouse: string | null;
  houses: HouseEntry[];
  ownClan: string | null;
  clans: StanceEntry[];
};

const SIZE = 560;
const CENTER = SIZE / 2;
const RING = 215;
const NODE_R = 34;

export const BondsFactions = () => {
  const { data } = useBackend<Data>();
  const {
    ownFaction,
    map = { nodes: [], edges: [] },
    ownHouse,
    houses = [],
    ownClan,
    clans = [],
  } = data;

  const nodes = map.nodes || [];
  const edges = map.edges || [];

  // Node positions are derived once from the ring order and shared with the edges.
  const placed: Record<string, { x: number; y: number; node: MapNode }> = {};
  nodes.forEach((node, index) => {
    const angle = (index / Math.max(nodes.length, 1)) * Math.PI * 2 - Math.PI / 2;
    placed[node.id] = {
      x: CENTER + Math.cos(angle) * RING,
      y: CENTER + Math.sin(angle) * RING,
      node,
    };
  });

  return (
    <Window title="Карта сил" width={640} height={780}>
      <Window.Content scrollable style={{ backgroundImage: 'none' }}>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Между фракциями">
              {!edges.length && (
                <Box opacity={0.6}>
                  Между фракциями пока ничего не произошло.
                </Box>
              )}
              <svg
                viewBox={`0 0 ${SIZE} ${SIZE}`}
                style={{ width: '100%', height: 'auto' }}
              >
                {edges.map((edge, index) => {
                  const from = placed[edge.a];
                  const to = placed[edge.b];
                  if (!from || !to) return null;
                  const midX = (from.x + to.x) / 2;
                  const midY = (from.y + to.y) / 2;
                  const thickness = 1 + Math.min(6, edge.weight / 15);
                  return (
                    <g key={index}>
                      <line
                        x1={from.x}
                        y1={from.y}
                        x2={to.x}
                        y2={to.y}
                        stroke={edge.accent}
                        strokeWidth={thickness}
                        opacity={0.65}
                      />
                      <text
                        x={midX}
                        y={midY - 3}
                        textAnchor="middle"
                        fill={edge.accent}
                        fontSize="10"
                      >
                        {edge.label}
                      </text>
                    </g>
                  );
                })}
                {nodes.map((node) => {
                  const spot = placed[node.id];
                  if (!spot) return null;
                  return (
                    <g key={node.id}>
                      <circle
                        cx={spot.x}
                        cy={spot.y}
                        r={NODE_R}
                        fill={node.own ? '#2a2418' : '#1b1b1b'}
                        stroke={node.accent}
                        strokeWidth={node.own ? 3 : 2}
                      />
                      <text
                        x={spot.x}
                        y={spot.y + 3}
                        textAnchor="middle"
                        fill="#e8e8e8"
                        fontSize="9"
                      >
                        {node.name.length > 13
                          ? `${node.name.slice(0, 12)}…`
                          : node.name}
                      </text>
                    </g>
                  );
                })}
              </svg>
              {!!ownFaction && (
                <Box mt={1} opacity={0.7}>
                  Обведена ваша фракция:{' '}
                  <Box inline bold color={ownFaction.accent}>
                    {ownFaction.name}
                  </Box>
                </Box>
              )}
            </Section>
          </Stack.Item>

          {!!ownClan && (
            <Stack.Item>
              <Section title={`Клан: ${ownClan}`}>
                <Stack vertical>
                  {clans.map((clan, index) => (
                    <Stack.Item key={`c${index}`}>
                      <Box inline bold color={clan.accent}>
                        {clan.name}
                      </Box>
                      <Box inline ml={1} bold color={clan.labelAccent}>
                        {clan.label}
                      </Box>
                      <Box opacity={0.6}>{clan.intensity}</Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
          )}

          {!!ownHouse && (
            <Stack.Item>
              <Section title={`Дом ${ownHouse}`}>
                {!houses.length && (
                  <Box opacity={0.6}>
                    С другими домами у вас пока ничего не случалось.
                  </Box>
                )}
                <Stack vertical>
                  {houses.map((house, index) => (
                    <Stack.Item key={`h${index}`}>
                      <Box inline bold>
                        {house.name}
                      </Box>
                      <Box inline ml={1} bold color={house.labelAccent}>
                        {house.label}
                      </Box>
                      <Box opacity={0.6}>
                        {house.intensity} · случаев: {house.incidents}
                      </Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
          )}

          {!ownFaction && !ownHouse && !ownClan && !edges.length && (
            <Stack.Item>
              <NoticeBox>Вам пока не о чем судить.</NoticeBox>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
