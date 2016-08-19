package no.dnt.sjekkut.ui;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.support.v7.widget.RecyclerView;
import android.view.View;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 18.08.2016.
 */

class ProjectSeparator extends RecyclerView.ItemDecoration {

    private final Paint mTextPainter;
    private final int mHeight;

    ProjectSeparator(Paint textPainter, int height) {
        mTextPainter = textPainter;
        mHeight = height;
    }

    @Override
    public void onDraw(Canvas canvas, RecyclerView parent, RecyclerView.State state) {
        super.onDraw(canvas, parent, state);

        int dividerLeft = parent.getPaddingLeft();
        int dividerRight = parent.getWidth() - parent.getPaddingRight();
        int xPos = dividerLeft + 30;

        int childCount = parent.getChildCount();
        for (int i = 0; childCount > i; i++) {
            View child = parent.getChildAt(i);
            String title = getSeparatorTitle(parent, child);
            if (title == null) {
                title = "";
            }
            RecyclerView.LayoutParams params = (RecyclerView.LayoutParams) child.getLayoutParams();
            int dividerTop = child.getTop() + params.topMargin;
            float yPos = dividerTop - (mHeight / 2.5f);
            canvas.drawText(title, xPos, yPos, mTextPainter);
        }
    }

    @Override
    public void getItemOffsets(Rect outRect, View view, RecyclerView parent, RecyclerView.State state) {
        super.getItemOffsets(outRect, view, parent, state);

        if (getSeparatorTitle(parent, view) != null) {
            outRect.set(0, mHeight, 0, 0);
        }
    }

    private String getSeparatorTitle(RecyclerView recycler, View view) {
        if (recycler.getAdapter() instanceof ProjectAdapter) {
            int adapterPosition = recycler.getChildAdapterPosition(view);
            return ((ProjectAdapter) recycler.getAdapter()).getSeparatorTitle(adapterPosition);
        }
        return null;
    }
}
