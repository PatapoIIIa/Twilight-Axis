import { useState } from 'react';
import {
  Box,
  Button,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type FactionEntry = {
  id: string;
  name: string;
  accent: string;
  clan: number | boolean;
};

type StanceEntry = {
  a: string;
  b: string;
  nameA: string;
  nameB: string;
  warmth: number;
  weight: number;
  label: string;
  labelAccent: string;
  history: number;
};

type HouseEntry = {
  nameA: string;
  nameB: string;
  warmth: number;
  weight: number;
  incidents: number;
  label: string;
  labelAccent: string;
};

type Data = {
  factions: FactionEntry[];
  stances: StanceEntry[];
  houses: HouseEntry[];
  storyteller: string | null;
  mapName: string | null;
  warmthMin: number;
  warmthMax: number;
  weightMax: number;
};

function StanceRow(props: {
  stance: StanceEntry;
  warmthMin: number;
  warmthMax: number;
  weightMax: number;
}) {
  const { act } = useBackend<Data>();
  const { stance, warmthMin, warmthMax, weightMax } = props;
  const [warmth, setWarmth] = useState(stance.warmth);
  const [weight, setWeight] = useState(stance.weight);

  return (
    <Stack align="center">
      <Stack.Item grow>
        <Box>
          {stance.nameA} — {stance.nameB}
        </Box>
        <Box inline bold color={stance.labelAccent}>
          {stance.label}
        </Box>
        <Box inline ml={1} opacity={0.5}>
          w {stance.warmth} / p {stance.weight} / записей {stance.history}
        </Box>
      </Stack.Item>
      <Stack.Item>
        <NumberInput
          value={warmth}
          minValue={warmthMin}
          maxValue={warmthMax}
          step={5}
          width="4rem"
          onChange={setWarmth}
        />
      </Stack.Item>
      <Stack.Item>
        <NumberInput
          value={weight}
          minValue={0}
          maxValue={weightMax}
          step={5}
          width="4rem"
          onChange={setWeight}
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          icon="check"
          onClick={() =>
            act('set_stance', { a: stance.a, b: stance.b, warmth, weight })
          }
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          icon="trash"
          color="bad"
          onClick={() => act('reset_stance', { a: stance.a, b: stance.b })}
        />
      </Stack.Item>
    </Stack>
  );
}

export const BondsAdmin = () => {
  const { data } = useBackend<Data>();
  const {
    stances = [],
    houses = [],
    storyteller,
    mapName,
    warmthMin = -100,
    warmthMax = 100,
    weightMax = 100,
  } = data;

  return (
    <Window title="Bonds: отношения фракций" width={780} height={720}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <NoticeBox info>
              Карта: {mapName || 'неизвестна'} · Сторителлер:{' '}
              {storyteller || 'не выбран'}
            </NoticeBox>
          </Stack.Item>

          <Stack.Item>
            <Section title={`Фракции (${stances.length} пар)`}>
              {!stances.length && (
                <Box opacity={0.6}>Пока нет ни одной установленной пары.</Box>
              )}
              <Stack vertical>
                {stances.map((stance, index) => (
                  <Stack.Item key={index}>
                    <StanceRow
                      stance={stance}
                      warmthMin={warmthMin}
                      warmthMax={warmthMax}
                      weightMax={weightMax}
                    />
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title={`Дома (${houses.length} пар)`}>
              {!houses.length && (
                <Box opacity={0.6}>
                  Между домами пока ничего не накопилось.
                </Box>
              )}
              <Stack vertical>
                {houses.map((house, index) => (
                  <Stack.Item key={index}>
                    <Box inline>
                      {house.nameA} — {house.nameB}
                    </Box>
                    <Box inline ml={1} bold color={house.labelAccent}>
                      {house.label}
                    </Box>
                    <Box inline ml={1} opacity={0.5}>
                      w {house.warmth} / p {house.weight} / случаев{' '}
                      {house.incidents}
                    </Box>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
