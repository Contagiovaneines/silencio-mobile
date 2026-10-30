"""Regression checks for generated Caio locomotion atlas foot contact."""

import unittest

from PIL import Image
from build_actor_sources import nobag_locomotion_cells



class ActorLocomotionAlignmentTest(unittest.TestCase):
    def test_no_backpack_locomotion_normalizes_body_scale_before_gait(self):
        sheet = Image.new("RGBA", (6 * 20, 8 * 20), (0, 0, 0, 0))
        for direction in range(8):
            for frame in range(6):
                height = 6 + ((direction * 3 + frame * 5) % 11)
                left = frame * 20 + 7
                top = direction * 20 + (20 - height)
                for y in range(top, direction * 20 + 20):
                    for x in range(left, left + 6):
                        sheet.putpixel((x, y), (30, 50, 70, 255))

        cells = nobag_locomotion_cells(sheet, "walk", target_height=97)
        self.assertEqual((len(cells), len(cells[0])), (8, 6))
        for direction, row in enumerate(cells):
            for frame, sprite in enumerate(row):
                with self.subTest(direction=direction, frame=frame):
                    bounds = sprite.getchannel("A").point(
                        lambda value: 255 if value > 96 else 0
                    ).getbbox()
                    self.assertIsNotNone(bounds)
                    self.assertEqual(bounds[3] - bounds[1], 97)
                    self.assertEqual(bounds[3], 120)


if __name__ == "__main__":
    unittest.main()
